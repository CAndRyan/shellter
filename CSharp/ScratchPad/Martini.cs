using System;
using System.IO;
using System.Text;

namespace ScratchPad {
	public partial class Program {
		public class Martini : IDriver {
			public MartiniMethod Method;
			private string _MethodName;
			public string MethodName {
				get {
					return _MethodName;
				}
				private set {
					_MethodName = value;
				}
			}
			
			public Martini(MartiniMethod method) {
				Method = method;
				MethodName = Enum.GetName(typeof(MartiniMethod), method);
			}
			public Martini() : this(MartiniMethod.Performant) { }

			public void Main(string[] args) {
				for (int i = 0; i < args.Length; i++) {
					int val;
					if (Int32.TryParse(args[i], out val)) {
						Console.WriteLine("Martini (size: {0}, method: {1}):", val, MethodName);
						if (!Print(val)) {
							Console.Error.WriteLine("Invalid input: '{0}'", val);
						}
					}
					else {
						Console.Error.WriteLine("Invalid input: '{0}'", args[i]);
					}
				}
			}

			private bool Print(int size) {
				switch (Method) {
					case MartiniMethod.Performant:
						//throw new NotImplementedException("No method has yet been determined as 'most performant'");
						return PrintGlassSlick(size);
					case MartiniMethod.Slick:
						return PrintGlassSlick(size);
					case MartiniMethod.Modified:
						return PrintGlassModifed(size);
					case MartiniMethod.Original:
						return PrintGlassOriginal(size);
					case MartiniMethod.Basic:
						return PrintGlassBasic(size);
					default:
						return false;
				}
			}

			/// <summary>
			/// Print a martini glass to the console --- 1 StringBuilder
			/// </summary>
			public static bool PrintGlassSlick(int size) {
				if (size < 1) { return false; }
				
				StringBuilder sb = new StringBuilder();
				string stemLine = String.Format("{0}{1}", new String(' ', size - 1), "|");

				for (int i = size; i > 0; i--) {
					sb.Insert(0, String.Format("{0}{1}{2}", new String(' ', i - 1), new String('0', 2 * (size - i) + 1), Environment.NewLine));
					sb.AppendLine(stemLine);
				}
				
				sb.AppendLine(new String('=', size * 2 - 1));
				Console.Write(sb.ToString());

				return true;
			}

			/// <summary>
			/// Print a martini glass to the console --- 2 StringBuilders
			/// </summary>
			public static bool PrintGlassModifed(int size) {
				if (size < 1) { return false; }
				
				StringBuilder sbTop = new StringBuilder();
				StringBuilder sbBottom = new StringBuilder();
				int maxWidth = size * 2 - 1;
				int mid = (maxWidth - 1) / 2;
				
				for (int i = 0; i < maxWidth; i = i + 2) {
					sbTop.AppendLine(new String(' ', i / 2) + new String('0', maxWidth - i));
					sbBottom.AppendLine(new String(' ', mid) + '|');
				}
				sbBottom.AppendLine(new String('=', maxWidth));

				Console.Write(sbTop.ToString());
				Console.Write(sbBottom.ToString());

				return true;
			}

			/// <summary>
			/// Print a martini glass to the console --- 1 StringBuilder and direct-to-console
			/// </summary>
			public static bool PrintGlassOriginal(int size) {
				if (size < 1) { return false; }
				
				StringBuilder sb = new StringBuilder();
				int maxWidth = size * 2 - 1;
				int mid = (maxWidth - 1) / 2;
				
				for (int i = 0; i < maxWidth; i = i + 2) {
					Console.WriteLine(new String(' ', i / 2) + new String('0', maxWidth - i));
					sb.AppendLine(new String(' ', mid) + '|');
				}
				
				sb.AppendLine(new String('=', maxWidth));
				Console.Write(sb.ToString());

				return true;
			}

			/// <summary>
			/// Print a martini glass to the console --- direct-to-console (2 loops)
			/// </summary>
			public static bool PrintGlassBasic(int size) {
				if (size < 1) { return false; }
				
				int maxWidth = size * 2 - 1;
				int mid = (maxWidth - 1) / 2;
				
				for (int i = 0; i < maxWidth; i = i + 2) {
					Console.WriteLine(new String(' ', i / 2) + new String('0', maxWidth - i));
				}
				for (int i = 0; i < maxWidth; i = i + 2) {
					Console.WriteLine(new String(' ', mid) + '|');
				}
				Console.WriteLine(new String('=', maxWidth));

				return true;
			}
		}

		/// <summary>
		/// Most to least performant after some quick testing (size=10, times=100): 
		/// Slick(1) avg=, Modified(2) avg=, Original(3) avg=, Basic(4) avg=
		/// </summary>
		public enum MartiniMethod {
			/// <summary>
			/// Whichever is the most performant of the actual methods
			/// </summary>
			Performant,
			/// <summary>
			/// Uses a single StringBuilder to build from the middle out within a single loop
			/// </summary>
			Slick,
			/// <summary>
			/// Uses 2 StringBuilders (top and bottom) within a single loop
			/// </summary>
			Modified,
			/// <summary>
			/// The original method, which uses a StringBuilder for the bottom and prints the top direct-to-console
			/// all within a single loop
			/// </summary>
			Original,
			/// <summary>
			/// A naive approach that uses 2 loops (top and bottom) and prints direct-to-console
			/// </summary>
			Basic
		}
	}
}
