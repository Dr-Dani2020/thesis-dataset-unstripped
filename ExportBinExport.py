# @category Export
# Usage in headless:
#   -postScript ExportBinExport.py "<output_path.BinExport>"
#
from java.io import File
from ghidra.util.task import ConsoleTaskMonitor
from com.google.security.binexport import BinExportExporter

p = currentProgram
if p is None:
    printerr("No program loaded. Use -import <binary>.")
    exit(1)

args = getScriptArgs()
if len(args) >= 1 and args[0]:
    out_path = args[0]
else:
    exe = p.getExecutablePath()
    if exe is None or exe == "":
        exe = p.getName()
    out_path = exe + ".BinExport"

addrset = p.getMemory().getAllInitializedAddressSet()
ok = BinExportExporter().export(File(out_path), p, addrset, ConsoleTaskMonitor())

if ok:
    println("OK BinExport: " + out_path)
else:
    printerr("Export failed: " + out_path)
