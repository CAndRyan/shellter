using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Drawing;

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

	public static class Imager {
		public static Bitmap ResizeImage(Bitmap imgToResize, int width, int height) {
			return new Bitmap(imgToResize, width, height);
		}

		public static void ResizeImage(string inFile, string outFile, int width, int height) {
			Bitmap img = new Bitmap(inFile);
			img = ResizeImage(img, width, height);
			img.Save(outFile);
		}

		public static Size GetImageSize(string inFile) {
			Bitmap img = new Bitmap(inFile);
			return new Size(img.Width, img.Height);
		}

		public static string GetImageSizeAsString(string inFile) {
			Size size = GetImageSize(inFile);
			return String.Format("Width: {0} --- Height: {1}", size.Width, size.Height);
		}
	}
}
