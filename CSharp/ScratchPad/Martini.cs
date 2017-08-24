using System;
using System.IO;
using System.Text;

namespace ScratchPad {
	public partial class Program {
		public class Martini : IDriver {
			public void Main(string[] args) {
				for (int i = 0; i < args.Length; i++) {
					int val;
					if (Int32.TryParse(args[i], out val)) {
						Console.WriteLine("Martini (size={0}):", val.ToString());
						if (!PrintGlass(val)) {
							Console.Error.WriteLine("Input out of range: '{0}'", val.ToString());
						}
					}
					else {
						Console.Error.WriteLine("Invalid input: '{0}'", args[i]);
					}
				}
			}

			public static bool PrintGlass(int size) {
				if (size < 1) { return false; }
				
				StringBuilder sb = new StringBuilder();
				int maxWidth = size * 2 - 1;
				int mid = (maxWidth - 1) / 2;
				
				for (int i = 0; i < maxWidth; i = i + 2) {
					Console.WriteLine(new String(' ', i / 2) + new String('0', maxWidth - i));
					sb.AppendLine(new String(' ', mid) + '|');
				}
				
				sb.AppendLine(new String('=', maxWidth));
				Console.WriteLine(sb.ToString());

				return true;
			}
		}
	}
}
