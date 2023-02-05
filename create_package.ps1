$plugin = 'Jpg2RawMetaCopy'
$version = '00.00.01'
$contents = @('*.lua', 'README.md', 'LICENSE')
if (-Not (Test-Path -Path 'build')) {
    New-Item -Type directory -Path build | Out-Null
}
$tempFolderPath = Join-Path $Env:Temp $(New-Guid)
New-Item -Type Directory -Path $tempFolderPath | Out-Null
$target = Join-Path $tempFolderPath "$plugin.lrplugin"
New-Item -Type Directory -Path $target | Out-Null
Copy-Item -Path $contents -Destination $target
Compress-Archive -Path $target -DestinationPath "build\${plugin}_$version.zip" -Force 
Remove-Item -Path $tempFolderPath -Recurse
