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
    using time = ChannelsTest.Timer;

    static class Timer
    {
        public static DateTimeOffset Now()
        {
            return DateTimeOffset.Now;
        }

        public static TimeSpan Since(DateTimeOffset start)
        {
            return Now() - start;
        }
    }

    public class Program {

        static int maxCount;

        static Task measure(DateTimeOffset start, string name) {
            var elapsed = time.Since(start);
            Console.Write("{0} took {1}", name, elapsed);
            Console.WriteLine();

            return Task.CompletedTask;
        }

        static async Task f(ChannelWriter<int> output, ChannelReader<int> input) {
            await output.WriteAsync(1 + await input.ReadAsync());
        }

        static async Task test() {
            await using var Go = new Go();
            Console.Write("Started, sending {0} messages (Channel).", maxCount);
            Console.WriteLine();
            Go.defer(measure, time.Now(), string.Format("Sending {0} messages (Channel)", maxCount));
            var finalOutput = Channel.CreateUnbounded<int>();
            (Channel<int>? left, var right) = (null, finalOutput);
            for (var i = 0; i < maxCount; i++) {
                (left, right) = (right, Channel.CreateBounded<int>(1));
                _ = f(left, right);
            }
            await right.Writer.WriteAsync(0);
            var x = await finalOutput.Reader.ReadAsync();
            Console.WriteLine(x);
        }

        static async Task f1(TaskCompletionSource<int> output, TaskCompletionSource<int> input) {
            output.SetResult(1 + await input.Task);
        }

        static async Task test1() {
            await using var Go = new Go();
            Console.Write("Started, sending {0} messages (TaskCompletionSource).", maxCount);
            Console.WriteLine();
            Go.defer(measure, time.Now(), string.Format("Sending {0} messages (TaskCompletionSource)", maxCount));
            var finalOutput = new TaskCompletionSource<int>();
            (TaskCompletionSource<int>? left, var right) = (null, finalOutput);
            for (var i = 0; i < maxCount; i++) {
                (left, right) = (right, new TaskCompletionSource<int>());
                _ = f1(left, right);
            }
            right.SetResult(0);
            var x = await finalOutput.Task;
            Console.WriteLine(x);
        }

        static async Task<int> f2(Task<int> input) {
            return 1 + await input;
        }

        static async Task test2() {
            await using var Go = new Go();
            Console.Write("Started, sending {0} messages (Task).", maxCount);
            Console.WriteLine();
            Go.defer(measure, time.Now(), string.Format("Sending {0} messages (Task)", maxCount));
            var initialInput = new TaskCompletionSource<int>();
            (Task<int>? left, var right) = (null, initialInput.Task);
            for (var i = 0; i < maxCount; i++) {
                (left, right) = (right, f2(right));
            }
            initialInput.SetResult(0);
            var x = await right;
            Console.WriteLine(x);
        }

        static async Task runTest(Func<Task> test) {
            await Task.Delay(1000);
            await test();
            await test();
            Console.Out.WriteLine();
        }

        static async Task runTestPal(Func<Task> test, string? label = default) {
            await Task.Delay(1000);
            {
                using var Go = new Go();
                label = null == label ? "" : string.Format(" ({0})", label);
                var runs = 10;
                Console.Write("Started, Running {0} tests{1}.", runs, label);
                Console.WriteLine();
                var cout = Console.Out;
                var fakecout = new StreamWriter(Stream.Null);
                Console.SetOut(fakecout);
                var a = new Task[runs];
                Go.defer(measure, time.Now(), string.Format("Running {0} tests{1}", runs, label));
                for (var i = 0; i < a.Length; i++) {
                    a[i] = Task.Run(test);
                }
                await Task.WhenAll(a);
                Console.SetOut(cout);
            }
            Console.WriteLine();
        }

        static async Task Main(string[] args) {
            if (!int.TryParse(args.FirstOrDefault(), out maxCount))
                maxCount = 1000000;

            await runTest(test);
            await runTest(test1);
            await runTest(test2);

            await runTestPal(test, "Channel");
            await runTestPal(test1, "TaskCompletionSource");
            await runTestPal(test2, "Task");
        }
    }

    public struct Go : IDisposable, IAsyncDisposable {

        Stack<Func<Task>> _defereds;

        Stack<Func<Task>> defereds {

            get => _defereds ??= new Stack<Func<Task>>();
        }

        public void defer(Func<Task> defered) {
            defereds.Push(defered);
        }

        public void defer<T>(Func<T, Task> defered, T arg) {
            defereds.Push(() => defered(arg));
        }

        public void defer<T1, T2>(Func<T1, T2, Task> defered, T1 arg1, T2 arg2) {
            defereds.Push(() => defered(arg1, arg2));
        }

        public void defer<T1, T2, T3>(Func<T1, T2, T3, Task> defered, T1 arg1, T2 arg2, T3 arg3) {
            defereds.Push(() => defered(arg1, arg2, arg3));
        }

        public void defer<T1, T2, T3, T4>(Func<T1, T2, T3, T4, Task> defered, T1 arg1, T2 arg2, T3 arg3, T4 arg4) {
            defereds.Push(() => defered(arg1, arg2, arg3, arg4));
        }

        public void Dispose() {
            DisposeAsync().AsTask().Wait();
        }

        public async ValueTask DisposeAsync() {
            var defereds = _defereds;
            if (defereds is null) {
                return;
            }
            List<Exception>? exs = null;
            for (; defereds.Count > 0;) {
                var defered = defereds.Pop();
                try {
                    await defered();
                } catch (Exception ex) {
                    (exs ??= new List<Exception>()).Add(ex);
                }
            }
            if (exs is not null) {
                throw new AggregateException(exs);
            }
        }
    }
}