# lanza_cobertura.ps1 -rom x.rom -desde 0x8000 -hasta 0xC000 -t 120 -salida work/cob.txt [-tecla "0 0x02"]
param([string]$rom, [string]$desde, [string]$hasta, [string]$t, [string]$salida, [string]$tecla = "", [switch]$quieto, [string]$maquina = "Philips_VG_8020")
$env:COB_DESDE = $desde; $env:COB_HASTA = $hasta; $env:COB_T = $t; $env:COB_SALIDA = $salida
if ($quieto) { $env:COB_QUIETO = "1" } else { Remove-Item Env:COB_QUIETO -ErrorAction SilentlyContinue }
if ($tecla) { $env:COB_TECLA = $tecla } else { Remove-Item Env:COB_TECLA -ErrorAction SilentlyContinue }
$args_ = @("-machine", $maquina, "-cart", $rom, "-script", "tools/omsx_cobertura.tcl")
Start-Process -FilePath "C:\Program Files\openMSX\openmsx.exe" -ArgumentList $args_ -Wait -WindowStyle Minimized
