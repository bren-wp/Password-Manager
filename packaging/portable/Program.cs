using System;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Collections.Generic;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text.Json;

internal static class Program
{
    private const string Version = "0.2.4-preview.2";
    private sealed class ManifestEntry
    {
        public string Path { get; set; } = "";
        public string Sha256 { get; set; } = "";
    }

    private static ManifestEntry[] ReadEmbeddedManifest()
    {
        using var stream = Assembly.GetExecutingAssembly()
            .GetManifestResourceStream("Veldigo.PayloadManifest")
            ?? throw new InvalidDataException("Nedostaje popis integriteta Veldiga.");
        return JsonSerializer.Deserialize<ManifestEntry[]>(stream)
            ?? throw new InvalidDataException("Neispravan popis integriteta Veldiga.");
    }

    private static bool VerifiedInstallation(string installation,
        ManifestEntry[] entries)
    {
        if (!Directory.Exists(installation) || entries.Length == 0)
            return false;
        var root = Path.GetFullPath(installation)
            .TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
        var expectedPaths = new HashSet<string>(
            StringComparer.OrdinalIgnoreCase);
        foreach (var entry in entries)
        {
            if (string.IsNullOrWhiteSpace(entry.Path) ||
                entry.Path.IndexOf(':') >= 0 || Path.IsPathRooted(entry.Path))
                return false;
            var destination = Path.GetFullPath(Path.Combine(
                installation, entry.Path.Replace('/', Path.DirectorySeparatorChar)));
            if (!destination.StartsWith(root, StringComparison.OrdinalIgnoreCase) ||
                !File.Exists(destination) || !expectedPaths.Add(destination))
                return false;
            using var stream = File.OpenRead(destination);
            var hash = Convert.ToHexString(SHA256.HashData(stream));
            if (!hash.Equals(entry.Sha256, StringComparison.OrdinalIgnoreCase))
                return false;
        }
        // Reject unexpected plugin/DLL payloads that were not part of the
        // embedded release bundle, including file drops beside veldigo.exe.
        foreach (var file in Directory.EnumerateFiles(
            installation, "*", SearchOption.AllDirectories))
        {
            if (!expectedPaths.Contains(Path.GetFullPath(file)))
                return false;
        }
        return true;
    }

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
            var manifest = ReadEmbeddedManifest();
            if (!VerifiedInstallation(installation, manifest))
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
                    if (!VerifiedInstallation(stage, manifest))
                        throw new InvalidDataException(
                            "Provjera integriteta Veldigo aplikacije nije uspjela.");
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
            if (!VerifiedInstallation(installation, manifest))
                throw new InvalidDataException("Neispravan instalacijski sadržaj.");
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
