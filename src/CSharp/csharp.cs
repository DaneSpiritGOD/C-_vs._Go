#nullable enable
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Channels;
using System.Threading.Tasks;
using System.Threading;
using System.Collections.Concurrent;
using System.Diagnostics.CodeAnalysis;
// [assembly: CLSCompliant(true)]

namespace ChannelsTest {
    public class Program {
        static async Task Benchmark(int pingpongCount, int iteration, bool debugMode) {
            var start = DateTimeOffset.Now;

            var input = CreateChannel();

            await input.Writer.WriteAsync(0);
            for (var i = 0; i < pingpongCount; i++) {
                var output = CreateChannel();
                _ = PingPong(output, input);
                input = output;
            }

            var finalValue = await input.Reader.ReadAsync();
            if(debugMode)
            {
                Console.WriteLine("{0}th iteration finished: took {1}, final value: {2}", iteration, DateTimeOffset.Now - start, finalValue);                
            }

            static async Task PingPong(ChannelWriter<int> out_, ChannelReader<int> in_) 
            {
                await out_.WriteAsync(1 + await in_.ReadAsync());
            }

            static Channel<int> CreateChannel()
            {
                return Channel.CreateBounded<int>(1);
            }
        }

        static async Task Main(string[] args) {
            var cla = CommandLineArg.Parse(args);

            if (cla.DebugMode) {
		        Console.WriteLine("Started, will run {0}(iterations) * {1}(ppc./iter.) of benchmark.", cla.Iterations, cla.PingPongCountPerIteration);
	        }

            var start = DateTimeOffset.Now;

            var tasks = new Task[cla.Iterations];
            for (var index = 0; index < cla.Iterations; ++index) {
                var index2 = index;
                tasks[index] = Task.Run(async () => await Benchmark(cla.PingPongCountPerIteration, index2, cla.DebugMode));
            }
            await Task.WhenAll(tasks);

            if (cla.DebugMode)
            {
		        Console.WriteLine("Finished totally, took {0}.", DateTimeOffset.Now - start);
	        } 
            else 
            {
		        Console.WriteLine("{0},{1},{2},{3},{4}", "csharp", cla.Iterations, cla.PingPongCountPerIteration, cla.Iterations*cla.PingPongCountPerIteration, DateTimeOffset.Now - start);
	        }
        }

        class CommandLineArg
        {
            public int Iterations { get; private set; } = 10;
            public int PingPongCountPerIteration { get; private set; } = 100_0000;
            public bool DebugMode { get; private set; } = false;

            public static CommandLineArg Parse(string[] args)
            {
                var cla = new CommandLineArg();

                if(args == null)
                {
                    return cla;
                }

                for(var index = 0; index< args.Length; ++index)
                {
                    switch(args[index])
                    {
                        case "-iters":
                            cla.Iterations = int.Parse(args[index+1]);
                            ++index;
                            break;
                        case "-ppc":
                            cla.PingPongCountPerIteration = int.Parse(args[index+1]);
                            ++index;
                            break;
                        case "-debug":
                            cla.DebugMode = bool.Parse(args[index+1]);
                            ++index;
                            break;
                        default:
                            break;
                    }
                }

                return cla;
            }
        }
    }
}