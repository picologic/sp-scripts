##########
# Most code for this script was pulled from the following blog entry
# https://blogs.technet.microsoft.com/sharepoint_-_inside_the_lines/2015/09/08/get-site-collection-size-with-powershell/
###########

param($outfile="sitecollection-sizes.txt")

Add-PSSnapin microsoft.sharepoint.powershell

$CurrentDate = Get-Date -format d
$WebApps = Get-SPWebApplication

"Title`tURL`tContent Database`tSize (GB)`tDate" | out-file $outfile

foreach($WebApp in $WebApps) {

	$Sites = Get-SPSite -WebApplication $WebApp -Limit All

	foreach($Site in $Sites) {
		$SizeInKB = $Site.Usage.Storage
		$SizeInGB = $SizeInKB/1024/1024/1024
		$SizeInGB = [math]::Round($SizeInGB,2)

		"$($Site.RootWeb.Title)`t$($Site.URL)`t$($Site.ContentDatabase.Name)`t$SizeInGB`t$CurrentDate" | out-file $outfile -append

		$Site.Dispose()
	}
}