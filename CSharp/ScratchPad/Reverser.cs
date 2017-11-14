using System;

namespace ScratchPad {
    public partial class Program {
        public class Reverser : IDriver {
            public ReverserMethod Method;
            private string _MethodName;
            public string MethodName {
                get {
                    return _MethodName;
                }
                private set {
                    _MethodName = value;
                }
            }

            public void Main(string[] args) {
				for (int i = 0; i < args.Length; i++) {
					double val;
					if (double.TryParse(args[i], out val)) {
						Console.WriteLine("Reverser (input: {0}, method: {1}):", val, MethodName);
						if (Reverse(val) == null) {
							Console.Error.WriteLine("Invalid input: '{0}'", val);
						}
					}
					else {
						Console.Error.WriteLine("Invalid input: '{0}'", args[i]);
					}
				}
			}

            public Reverser(ReverserMethod method) {
                Method = method;
                MethodName = Enum.GetName(typeof(ReverserMethod), method);
            }
            public Reverser() : this(ReverserMethod.Recursive) { }

            private double? Reverse(double num) {
                switch (Method) {
                    case ReverserMethod.Recursive:
                        return ReverseRecursive(num, 0.0);
                    case ReverserMethod.While:
                        return ReverseWhileLoop(num);
                    default:
                        return null;
                }
            }
            
            public static double ReverseWhileLoop(double num) {
                double retVal = 0;
                
                do {
                    retVal = (retVal * 10) + (num % 10);
                    num = Math.Floor(num / 10);
                } while (num > 0);
                
                return retVal;
            }
            
            public static double ReverseRecursive(double num, double build) {
                build = (build * 10) + (num % 10);
                num = Math.Floor(num / 10);
                
                return num > 0 ? ReverseRecursive(num, build) : build;
            }
        }

        public enum ReverserMethod {
            Recursive,
            While
        }
    }
}
