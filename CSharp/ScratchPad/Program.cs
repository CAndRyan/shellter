using System;
using System.Linq;
using System.Diagnostics;

namespace ScratchPad {
    public partial class Program {
        public static void Main(string[] args) {
            if (args.Length > 0) {
                IDriver driver = null;
                Stopwatch watch = null;
                int loopCount = 1;
                long[] WatchTicks = new long[loopCount];

                if (args.Length > 1 && args[args.Length - 1].StartsWith("--measure", StringComparison.OrdinalIgnoreCase)) {
                    Int32.TryParse(args[args.Length - 1].ToLower().Replace("--measure", ""), out loopCount);
                    watch = new Stopwatch();
                    args = args.Take(args.Length - 1).ToArray();
                }

                switch (args[0].ToLower()) {
                    case "--martini":
                        if (args.Length > 1 && args[1].StartsWith("-")) {
                            MartiniMethod method;
                            if (Enum.TryParse(args[1].Replace("-", ""), out method) && Enum.IsDefined(typeof(MartiniMethod), method)) {
                                driver = new Martini(method);
                                args = args.Skip(1).ToArray();
                            }
                            else {
                                Console.Error.WriteLine("Invalid method value: '{0}'", args[1]);
                                return;
                            }
                        }
                        else {
                            driver = new Martini();
                        }
                        break;
                    default:
                        Console.Error.WriteLine("Invalid command: '{0}'", args[0]);
                        return;
                }
                
                do {
                    watch?.Start();
                    try {
                        driver.Main(args.Skip(1).ToArray());
                    }
                    catch (Exception ex) {
                        Console.Error.WriteLine("Error Encountered: {0}: {1}\n{2}", ex.GetType().FullName, ex.Message, ex.StackTrace);
                        loopCount = 0;
                    }
                    finally {
                        watch?.Stop();
                        if (watch != null) {
                            Console.WriteLine("Elapsed time (ticks): {0}", watch.ElapsedTicks);
                            WatchTicks[loopCount] = watch.ElapsedTicks;
                            watch.Reset();
                        }
                        loopCount--;
                    }
                } while (loopCount > 0)
            }
        }

        public interface IDriver {
            void Main(string[] args);
        }
    }
}
