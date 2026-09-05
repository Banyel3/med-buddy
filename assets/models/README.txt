pills_detection.tflite — YOLOv8s pill/capsule detector, float32.

Source: https://github.com/seblful/pills-detection (best_model.onnx, CC BY 4.0;
attribute seblful in app credits). The repo ships no .pt and no .tflite.

Expected by lib/features/verification/services/pill_detection_service.dart:
  input  [1, 640, 640, 3] float32, RGB, 0..1 (NHWC)
  output [1, 6, 8400]     float32  (cx, cy, w, h, conf_capsule, conf_tablet)

Do NOT ship the float16 export: LiteRT's builtin CONV_2D refuses fp16 inputs
at prepare time ("Node number 1 (CONV_2D) failed to prepare"), the model never
allocates and pill confidence is always 0. The upstream ONNX is also exported
with a hard-baked batch of 8, which must be patched to 1 before conversion.

Regenerate (Python 3.12 venv):
  uv venv -p 3.12 .venv
  uv pip install -p .venv/bin/python "tensorflow==2.19.*" "tf_keras==2.19.*" \
      onnx onnx2tf onnxsim onnx_graphsurgeon sng4onnx ai-edge-litert psutil
  curl -L -o best_model.onnx \
      https://github.com/seblful/pills-detection/raw/HEAD/best_model.onnx
  .venv/bin/python - <<'PY'
  import onnx, onnxsim
  from onnx import numpy_helper
  m = onnx.load("best_model.onnx"); g = m.graph
  inits = {i.name: i for i in g.initializer}
  consts = {n.output[0]: n for n in g.node if n.op_type == "Constant"}
  for n in g.node:                      # batch 8 -> 1 in every Reshape shape
      if n.op_type != "Reshape": continue
      shp = n.input[1]
      if shp in inits:
          a = numpy_helper.to_array(inits[shp]).copy()
          if a.ndim == 1 and a[0] == 8: a[0] = 1; inits[shp].CopyFrom(numpy_helper.from_array(a, shp))
      elif shp in consts:
          t = consts[shp].attribute[0].t; a = numpy_helper.to_array(t).copy()
          if a.ndim == 1 and a[0] == 8: a[0] = 1; t.CopyFrom(numpy_helper.from_array(a, t.name))
  g.input[0].type.tensor_type.shape.dim[0].dim_value = 1
  g.output[0].type.tensor_type.shape.dim[0].dim_value = 1
  s, ok = onnxsim.simplify(m, overwrite_input_shapes={"images": [1, 3, 640, 640]})
  onnx.save(s, "best_b1.onnx")
  PY
  .venv/bin/onnx2tf -i best_b1.onnx -o out -dsm
  cp out/best_b1_float32.tflite pills_detection.tflite

onnx2tf downloads a sample .npy for a sanity inference; if that download is
blocked, create any (20,128,128,3) float32 .npy with that filename in the cwd.
