using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;

namespace CRyan.Tools {
	public static class Reverser {
		public static double ReverseWhileLoop(double num) {
			double retVal = 0;
			List<int> digits = new List<int>();
			int count = 0;
			
			do {
				digits.Add((int)(num % 10));
				num = Math.Floor(num / 10);
				count++;
			} while (num > 0);
			
			for (int i = 0; i < count; i++) {
				retVal += digits[i] * Math.Pow(10, count - i - 1);
			}
			
			return retVal;
		}
		
		private static double TimeMethod(Func<double, double> method, double num) {
			Stopwatch sw = Stopwatch.StartNew();
			double retVal = method(num);
			sw.Stop();
			Console.WriteLine(String.Format("Elapsed time: {0}", sw.Elapsed));
			return retVal;
		}
		private static double TimeMethod(Func<double, List<int>, double> method, double num) {
			Stopwatch sw = Stopwatch.StartNew();
			double retVal = method(num, new List<int>());
			sw.Stop();
			Console.WriteLine(String.Format("Elapsed time: {0}", sw.Elapsed));
			return retVal;
		}
		
		public static double ReverseWhileLoopTimed(double num) {
			return TimeMethod(ReverseWhileLoop, num);
		}
		
		public static double ReverseRecursive(double num, List<int> digits) {
			digits.Add((int)(num % 10));
			num = Math.Floor(num / 10);
			
			//if (num > 0) {
			//	return ReverseRecursive(num, digits);
			//}
			//else {
			//	return digits.Select((digit, index) => digit * Math.Pow(10, digits.Count - index - 1)).Sum();
			//}
			
			return num > 0 ? ReverseRecursive(num, digits) : 
				digits.Select((digit, index) => digit * Math.Pow(10, digits.Count - index - 1)).Sum();
		}
		
		public static double ReverseRecursiveTimed(double num) {
			return TimeMethod(ReverseRecursive, num);
		}
	}
}
