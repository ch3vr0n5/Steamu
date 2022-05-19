[xml]$dirXml = Get-Content .\directories.xml

$pathLocalAppData = $env:LOCALAPPDATA
$pathHome = 'test'

$directories = $dirXml.SelectNodes('//sub-directory')

$directories | ForEach-Object{
    $basePath = $ExecutionContext.InvokeCommand.ExpandString($_.parentnode.basePath)
    $baseName = $_.parentnode.name
    $subName = $_.name
    Write-Host "$basePath/$baseName/$subName"
}