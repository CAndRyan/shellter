using System;
using System.IO;
using System.Linq;
using System.Diagnostics;

namespace ScratchPad {
    public partial class Program {
        public static void Main(string[] args) {
            if (args.Length > 0 && args[0].StartsWith("--")) {
                IDriver driver = null;
                Stopwatch watch = null;
                int loopCount = 1;
                long sumTicks = 0;
                long sumMs = 0;
                bool hasError = false;

                if (args.Length > 1 && args[args.Length - 1].StartsWith("--measure", StringComparison.OrdinalIgnoreCase)) {
                    // If the parsed value is less than 1 or it failed to parse, reset to 1 loop
                    if (!Int32.TryParse(args[args.Length - 1].ToLower().Replace("--measure", ""), out loopCount) || loopCount < 1) {
                        loopCount = 1;
                    }
                    watch = new Stopwatch();
                    args = args.Take(args.Length - 1).ToArray();
                }

                bool measure = watch != null;
                string cmd = args[0].ToLower().Replace("--", "");

                switch (cmd) {
                    case "martini":
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
                args = args.Skip(1).ToArray();
                  
                Console.WriteLine("ScratchPad executing (command: '{0}', measure: {1}, loops: {2})...", cmd, measure, loopCount);
                
                // execute an inital pass to prepare the JIT compiler for writing the same output to the console
                // without this, the first pass will always be significantly higher than subsequent ones
                if (measure) {
                    TextWriter originalOut = Console.Out;
                    Console.SetOut(TextWriter.Null);

                    for (int i = 0; !hasError && i < 5; i++) {
                        try {
                            driver.Main(args);
                        }
                        catch (Exception ex) {
                            Console.SetOut(originalOut);
                            Console.Error.WriteLine("Error encountered during measure setup: {0}: {1}\n{2}", ex.GetType().FullName, ex.Message, ex.StackTrace);
                            hasError = true;
                        }
                        finally {
                            if (!hasError) { Console.SetOut(originalOut); }
                        }
                    }
                }
                
                for (int i = 0; !hasError && i < loopCount; i++) {
                    watch?.Start();
                    try {
                        driver.Main(args);
                    }
                    catch (Exception ex) {
                        Console.Error.WriteLine("Error encountered: {0}: {1}\n{2}", ex.GetType().FullName, ex.Message, ex.StackTrace);
                        hasError = true;
                    }
                    finally {
                        watch?.Stop();
                        if (measure) {
                            Console.WriteLine("Elapsed time (ticks): {0}ms ({1})", watch.ElapsedMilliseconds, watch.ElapsedTicks);
                            sumMs += watch.ElapsedMilliseconds;
                            sumTicks += watch.ElapsedTicks;
                            watch.Reset();
                        }
                    }
                }

                if (measure && !hasError && loopCount > 1) {
                    Console.WriteLine("Average time over {0} loops (ticks): {1}ms ({2})", loopCount, sumMs / loopCount, sumTicks / loopCount);
                }
            }
            else {
                Console.WriteLine("No arguments provided...");
            }
        }

        public interface IDriver {
            void Main(string[] args);
        }
    }
}
