###################
# Generate Content Inventory
# This script generates a content inventory file from a web including all lists, libraries
# and subwebs
###################

param(
    [string]$url,
    [string]$outfile="content-inventory.txt"
)

if ( (Get-PSSnapin -Name "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null )
{
    Add-PSSnapin "Microsoft.SharePoint.PowerShell"
}

function AnalyzeWeb($web) {
    
    $records = @();

    $web.Lists | foreach {
        $items = @();
        if ($_.BaseType -eq "DocumentLibrary") {
            $items = AnalyzeDocumentLibrary $_
        } else {
            $items = AnalyzeList $_
        }
        if ($items.Length -gt 0) {
            $items | foreach { $records += $_ }
        }
    }
    
    $web.Webs | foreach {
        $webs = AnalyzeWeb $_;
        if ($webs.Length -gt 0) {
            $webs | foreach { $records += $_ }
        }
    }
    
    $records += BuildRecord $web.Url $web.Title "Web" $web.Created $web.LastItemModifiedDate $web.Author "" (($records | measure-object Size -sum).Sum) $records.Length
    
    return $records;
}

function AnalyzeDocumentLibrary($doclib) {
    $records = @();
    
    $items = $doclib.GetItems();
    $items | foreach {
        if ($_.Folder -ne $null) {
            write-host "folder";
        } else {
            $records += BuildRecord ($_.Web.Url + "/" + $_.Url) $_.Title "Document" $_["Created"] $_["Modified"] $_["Author"] $_["Editor"] $_.File.TotalLength 0
        }
    }
    
    $records += BuildRecord ($doclib.ParentWeb.Url + "/" + $doclib.RootFolder.Url) $doclib.Title "Document Library" $doclib.Created $doclib.LastItemModifiedDate "" "" (($records | measure-object Size -sum).Sum) $records.Length
    
    return $records;
}

function AnalyzeList($list) {
    $records = @();
    
    $items = $list.GetItems();
    $items | foreach {
        if ($_.Folder -ne $null) {
            write-host "folder";
        } else {
            $records += BuildRecord ($_.Web.Url + "/" + $_.Url) $_.Title "Item" $_["Created"] $_["Modified"] $_["Author"] $_["Editor"] 0 0
        }
    }
    
    $records += BuildRecord ($list.ParentWeb.Url + "/" + $list.RootFolder.Url) $list.Title "List" $list.Created $list.LastItemModifiedDate "" "" (($records | measure-object Size -sum).Sum) $records.Length

    return $records;
}

function WriteOutput($records, $outfile) {
    "Url`tName`tType`tExtension`tCreated`tLastModified`tCreatedBy`tModifiedBy`tSize`tChildren`n" | out-file -filepath $outfile -encoding ASCII
    $records | foreach {
        "$($_.Url)`t$($_.Name)`t$($_.Type)`t$($_.Extension)`t$($_.Created)`t$($_.LastModified)`t$($_.CreatedBy)`t$($_.ModifiedBy)`t$($_.Size)`t$($_.Children)`n" | out-file -filepath $outfile -encoding ASCII -append
    }
}

function BuildRecord($url, $name, $type, $created, $lastmod, $createdby, $modby, $size, $children) {
    $ext = [System.IO.Path]::GetExtension($url).Trim('.')
    return New-Object psobject -Property @{ 
        Url = $url; 
        Name = $name;
        Type = $type;
        Extension = $ext;
        Created = $created;
        LastModified = $lastmod;
        CreatedBy = (FriendlyUserName $createdby);
        ModifiedBy = (FriendlyUserName $modby);
        Size = $size;
        Children = $children 
    };
}

function FriendlyUserName($user) {
    $username = $user.ToString()
    $pos = $username.IndexOf("#")
    return $username.Substring($pos+1)    
}

$root = get-spweb $url
$data = AnalyzeWeb $root
WriteOutput $data $outfile