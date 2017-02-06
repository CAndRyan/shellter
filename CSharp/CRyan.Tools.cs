using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;

namespace CRyan.Tools {
	public static class Reverser {
		public static double ReverseWhileLoop(double num) {
			double retVal = 0;
			
			do {
				retVal = (retVal * 10) + (num % 10);
				num = Math.Floor(num / 10);
			} while (num > 0);
			
			return retVal;
		}
		
		private static double TimeMethod(Func<double, double> method, double num) {
			Stopwatch sw = Stopwatch.StartNew();
			double retVal = method(num);
			sw.Stop();
			Console.WriteLine(String.Format("Elapsed time (ms): {0}", sw.Elapsed.TotalMilliseconds));
			return retVal;
		}
		private static double TimeMethod(Func<double, double, double> method, double num) {
			Stopwatch sw = Stopwatch.StartNew();
			double retVal = method(num, 0);
			sw.Stop();
			Console.WriteLine(String.Format("Elapsed time (ms): {0}", sw.Elapsed.TotalMilliseconds));
			return retVal;
		}
		
		public static double ReverseWhileLoopTimed(double num) {
			return TimeMethod(ReverseWhileLoop, num);
		}
		
		public static double ReverseRecursive(double num, double build) {
			build = (build * 10) + (num % 10);
			num = Math.Floor(num / 10);
			
			return num > 0 ? ReverseRecursive(num, build) : build;
		}
		
		public static double ReverseRecursiveTimed(double num) {
			return TimeMethod(ReverseRecursive, num);
		}
	}
}
