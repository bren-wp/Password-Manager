using System;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Runtime.InteropServices;

internal static class Program
{
    private const string Version = "0.2.3-preview.2";
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int MessageBoxW(IntPtr hWnd, string text,
        string caption, uint type);
    [STAThread]
    private static int Main()
    {
        try
        {
            var cacheRoot = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "Veldigo", "Portable");
            Directory.CreateDirectory(cacheRoot);
            var installation = Path.Combine(cacheRoot, Version);
            var exe = Path.Combine(installation, "veldigo.exe");
            if (!File.Exists(exe))
            {
                var stage = Path.Combine(cacheRoot,
                    ".stage-" + Guid.NewGuid().ToString("N"));
                Directory.CreateDirectory(stage);
                try
                {
                    using var payload = Assembly.GetExecutingAssembly()
                        .GetManifestResourceStream("Veldigo.Payload")
                        ?? throw new InvalidOperationException("Veldigo payload nije ugrađen.");
                    ZipFile.ExtractToDirectory(payload, stage);
                    if (!File.Exists(Path.Combine(stage, "veldigo.exe")))
                        throw new InvalidDataException("Nedostaje Veldigo izvršna datoteka.");
                    if (Directory.Exists(installation))
                        Directory.Delete(installation, recursive: true);
                    Directory.Move(stage, installation);
                }
                catch
                {
                    if (Directory.Exists(stage)) Directory.Delete(stage, recursive: true);
                    throw;
                }
            }
            var start = new ProcessStartInfo(exe)
            {
                UseShellExecute = false,
                WorkingDirectory = installation,
            };
            using var process = Process.Start(start);
            if (process is null)
                throw new InvalidOperationException("Veldigo nije pokrenut.");
            return 0;
        }
        catch (Exception e)
        {
            MessageBoxW(IntPtr.Zero,
                "Veldigo nije moguće pokrenuti.\n\n" + e.Message,
                "Veldigo", 0x10);
            return 1;
        }
    }
}
