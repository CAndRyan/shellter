using System;
using System.Linq;

namespace ScratchPad {
    public partial class Program {
        public static void Main(string[] args) {
            if (args.Length > 0) {
                IDriver driver = null;

                switch (args[0].ToLower()) {
                    case "--martini": 
                        driver = new Martini();
                        break;
                    default:
                        Console.Error.WriteLine("Invalid command: '{0}'", args[0]);
                        break;
                }

                if (driver != null) {
                    driver.Main(args.Skip(1).ToArray());
                }
            }
        }

        public interface IDriver {
            void Main(string[] args);
        }
    }
}
