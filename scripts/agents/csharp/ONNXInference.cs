using Godot;
using Microsoft.ML.OnnxRuntime;
using Microsoft.ML.OnnxRuntime.Tensors;
using System.Collections.Generic;
using System.Linq;

namespace GodotONNX
{
	/// <include file='docs/ONNXInference.xml' path='docs/members[@name="ONNXInference"]/ONNXInference/*'/>
	public partial class ONNXInference : GodotObject
	{

		private InferenceSession session;
		private string modelPath;
		private int batchSize;
		private List<string> outputNames;

		private SessionOptions SessionOpt;

		/// <summary>
		/// Loads the model and returns the list of action output names (sorted alphabetically,
		/// matching the order used during ONNX export).
		/// </summary>
		public Godot.Collections.Array<string> Initialize(string Path, int BatchSize)
		{
			modelPath = Path;
			batchSize = BatchSize;
			SessionOpt = SessionConfigurator.MakeConfiguredSessionOptions();
			session = LoadModel(modelPath);
			outputNames = session.OutputMetadata.Keys.ToList();

			var result = new Godot.Collections.Array<string>();
			foreach (var name in outputNames)
				result.Add(name);
			return result;
		}

		private static DenseTensor<float> ToTensor(Godot.Collections.Array<float> values, int batchSize)
		{
			var span = new float[values.Count];
			for (int i = 0; i < values.Count; i++)
				span[i] = values[i];
			return new DenseTensor<float>(span, new int[] { batchSize, values.Count });
		}

		private Godot.Collections.Dictionary<string, Godot.Collections.Array<float>> RunSession(IReadOnlyCollection<NamedOnnxValue> inputs)
		{
			IDisposableReadOnlyCollection<DisposableNamedOnnxValue> results;
			try
			{
				results = session.Run(inputs, outputNames);
			}
			catch (OnnxRuntimeException e)
			{
				GD.Print("Error at inference: ", e);
				return null;
			}

			var output = new Godot.Collections.Dictionary<string, Godot.Collections.Array<float>>();
			foreach (var result in results)
			{
				var arr = new Godot.Collections.Array<float>();
				if (result.ElementType == TensorElementType.Float)
				{
					foreach (float f in result.AsEnumerable<float>())
						arr.Add(f);
				}
				else if (result.ElementType == TensorElementType.Int64)
				{
					foreach (long l in result.AsEnumerable<long>())
						arr.Add((float)l);
				}
				output[result.Name] = arr;
			}

			results.Dispose();
			return output;
		}

		/// <include file='docs/ONNXInference.xml' path='docs/members[@name="ONNXInference"]/Run/*'/>
		public Godot.Collections.Dictionary<string, Godot.Collections.Array<float>> RunInference(Godot.Collections.Array<float> obs)
		{
			IReadOnlyCollection<NamedOnnxValue> inputs = new List<NamedOnnxValue>
			{
				NamedOnnxValue.CreateFromTensor("obs", ToTensor(obs, batchSize)),
			};
			return RunSession(inputs);
		}

		/// <summary>
		/// Same as RunInference, but for recurrent (LSTM) models exported with a
		/// hidden state in/out (see executables/export_rl_module_to_onnx.py).
		/// Only called by callers that know the loaded model is recurrent
		/// (GDScript side: InferenceManager.model_has_memory) -- this class does
		/// not inspect the model to decide which method should be used.
		/// </summary>
		public Godot.Collections.Dictionary<string, Godot.Collections.Array<float>> RunInferenceWithState(
			Godot.Collections.Array<float> obs,
			Godot.Collections.Array<float> stateH,
			Godot.Collections.Array<float> stateC)
		{
			IReadOnlyCollection<NamedOnnxValue> inputs = new List<NamedOnnxValue>
			{
				NamedOnnxValue.CreateFromTensor("obs", ToTensor(obs, batchSize)),
				NamedOnnxValue.CreateFromTensor("state_in_h", ToTensor(stateH, batchSize)),
				NamedOnnxValue.CreateFromTensor("state_in_c", ToTensor(stateC, batchSize)),
			};
			return RunSession(inputs);
		}

		/// <include file='docs/ONNXInference.xml' path='docs/members[@name="ONNXInference"]/Load/*'/>
		public InferenceSession LoadModel(string Path)
		{
			using Godot.FileAccess file = FileAccess.Open(Path, Godot.FileAccess.ModeFlags.Read);
			byte[] model = file.GetBuffer((int)file.GetLength());
			return new InferenceSession(model, SessionOpt);
		}
		public void FreeDisposables()
		{
			session.Dispose();
			SessionOpt.Dispose();
		}
	}
}
