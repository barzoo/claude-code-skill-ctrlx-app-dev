/**
 * ctrlX Data Layer Provider Template (C#/.NET)
 * NuGet: Datalayer >= 2.4 (Bosch Rexroth private feed)
 * Feed: https://nexus.boschrexroth.com/repository/nuget-hosted/
 */
using System;
using System.Threading;
using System.Threading.Tasks;
using Datalayer;

namespace {Company}.{App}
{
    class Program
    {
        static async Task Main(string[] args)
        {
            using var cts = new CancellationTokenSource();
            Console.CancelKeyPress += (_, e) =>
            {
                e.Cancel = true;
                cts.Cancel();
            };

            // Handle SIGTERM (systemd stop)
            AppDomain.CurrentDomain.ProcessExit += (_, _) => cts.Cancel();

            await RunProviderAsync(cts.Token);
        }

        static async Task RunProviderAsync(CancellationToken ct)
        {
            // Initialize system (empty = use snap default IPC socket)
            using var system = new DatalayerSystem();
            system.Start(isSingleNodeApp: false);

            // Create provider via IPC (inside snap)
            using var provider = system.Factory.CreateProvider("ipc://");
            if (provider is null)
            {
                Console.Error.WriteLine("[provider] Failed to create provider");
                return;
            }

            var startResult = provider.Start();
            if (startResult != DlResult.DL_OK)
            {
                Console.Error.WriteLine($"[provider] Start failed: {startResult}");
                return;
            }

            // Register nodes
            var paths = new[]
            {
                "{company}/{app}/sensor/value",
                "{company}/{app}/sensor/status",
            };

            var sensorNode = new SensorNode();
            foreach (var path in paths)
            {
                var r = provider.RegisterNode(path, sensorNode);
                if (r != DlResult.DL_OK)
                    Console.Error.WriteLine($"[provider] Failed to register {path}: {r}");
                else
                    Console.WriteLine($"[provider] Registered: {path}");
            }

            Console.WriteLine("[provider] Running. Press Ctrl+C to stop.");

            try
            {
                await Task.Delay(Timeout.Infinite, ct);
            }
            catch (OperationCanceledException) { }

            // Graceful shutdown
            foreach (var path in paths)
                provider.UnregisterNode(path);

            provider.Stop();
            system.Stop();
            Console.WriteLine("[provider] Stopped.");
        }
    }

    /// <summary>Provider node implementation.</summary>
    class SensorNode : IProviderNode
    {
        private double _value = 0.0;

        public DlResult OnRead(string address, out IVariant output)
        {
            output = new Variant(_value);
            return DlResult.DL_OK;
        }

        public DlResult OnWrite(string address, IVariant input, out IVariant output)
        {
            output = Variant.Empty;
            if (input.DataType != DlDataType.float64)
                return DlResult.DL_TYPE_MISMATCH;

            _value = input.ToDouble();
            Console.WriteLine($"[provider] Written: {_value}");
            return DlResult.DL_OK;
        }

        public DlResult OnMetadata(string address, out IVariant output)
        {
            // Return JSON metadata (simplified; use Flatbuffers for production)
            output = new Variant("{\"unit\": \"°C\", \"description\": \"Sensor value\"}");
            return DlResult.DL_OK;
        }
    }
}
