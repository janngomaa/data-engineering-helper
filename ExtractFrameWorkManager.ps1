function Main(){
	$ModelsPath = "T:\Temp\models_all\"
	$date = Get-Date -Format "yyyy-MM-dd"
	$HomeDir = "T:\Temp\model_data_$date\"
	$LogFile = $HomeDir + "log_$date.log"
	$PackDir = $HomeDir + "packages\"
	$DataSourceDir = $HomeDir + "data-sources\"
	$QuerySubjectDir = $HomeDir + "query-subjects\"
	$dirs = $HomeDir, $PackDir, $DataSourceDir, $QuerySubjectDir
	ForEach($d in $dirs){
		if (Test-Path $d) {
			Remove-Item $d -Recurse -Force
		}
		New-Item -ItemType Directory -Path $d
	}

    $Ids = Get-ChildItem -Path $ModelsPath |Select Name
	$NbFiles = $Ids.Count
	
	Write-Output "Extraction started. For more information see log file: $LogFile."
	
	Write-Output "Extraction started with the following params:" >> $LogFile
	Write-Output "Models Location = $ModelsPath." >> $LogFile
	Write-Output "HomeDir = $HomeDir.`nNumber of Files (model.xml) to Process = $NbFiles." >> $LogFile
	
    ForEach ($Id in $Ids){
        
        $FileId = $Id.Name
        $Path = $ModelsPath + $FileId
		
		Write-Output "Processing File $FileId." >> $LogFile
		
        [xml]$xmlElm = Get-Content -Path $Path
        # Get Project Name
        $ProjectName = $xmlElm.project.name
        $Packages = $xmlElm.project.packages.package
        $Namespaces = $xmlElm.project.namespace
        $DataSources = $xmlElm.project.dataSources.dataSource
       
        if($DataSources){
            ExtractDataSourcessData -ds $DataSources
        }

        if($DataSources -eq $null){
            Write-Output "*** DataSources is null for the file $FileId." >> $LogFile
        }

        if($Packages){
            ExtractPacksData -Packs $Packages
        }

        if($Packages -eq $null){
            Write-Output "*** Packages is null for the file $FileId." >> $LogFile
        }

        if($Namespaces){
            ExtractQSData -RootNamespace $Namespaces
        }

        if($Namespaces -eq $null){
            Write-Output "*** Namespaces is null for the file $FileId." >> $LogFile
        }
    }
}

function ExtractDataSourcessData($ds) {
    $DsDest = $DataSourceDir + $FileId + ".csv"
    $ds | Export-Csv -Delimiter "|" -NoTypeInformation -Path $DsDest
}

# Extract Packages
function ExtractPacksData($Packs) {
    $PacksData = @()
    ForEach($pack in $Packs) {
        $PackData = (New-Object PSObject | Add-Member -PassThru NoteProperty "PackageName" $pack.name."#text" `
            | Add-Member -PassThru NoteProperty "PackageDescription" $pack.description."#text" `
            | Add-Member -PassThru NoteProperty "LastChanged" $pack.lastChanged `
            | Add-Member -PassThru NoteProperty "LastChangedBy" $pack.lastChangedBy `
            | Add-Member -PassThru NoteProperty "LastPublished" $pack.lastPublished `
            | Add-Member -PassThru NoteProperty "LastPublishedCMPath" $pack.lastPublishedCMPath  `
            | Add-Member -PassThru NoteProperty "ProjectName" $ProjectName  `
            | Add-Member -PassThru NoteProperty "SourceFileId" $FileId
        )
        $PacksData = $PackData
    }

    $PackDest = $PackDir + $FileId + ".csv"
    $PacksData | Export-Csv -Delimiter "|" -NoTypeInformation -Path $PackDest
}

# Extract Single QuerySubject Info
# $node: parent namespace
# $QSNode: the querySubject to extract
function Process-QSNode($node, $QSNode) {
    $sep = "|@"
    $sql = $QSNode.definition.dbQuery.sql
    $rawSql = $null
    $sourceTable = $sql.table -replace '[\r\n\s]+', ' '

    $sql.ChildNodes | ForEach-Object {
        if ($_.NodeType -eq 'Text') {
            $rawSql += $_.Value
        } else {
            $rawSql += $_.InnerText
        }

    }
    if($rawSql -eq $null ){
        $rawSql = $sql."#text"
    }
    $rawSql = $rawSql -replace '[\r\n\s]+', ' '
    $modelQuery = $QSNode.definition.modelQuery.sql."#text"  -replace '[\r\n\s]+', ' '

    $result = (New-Object PSObject | Add-Member -PassThru NoteProperty "NamespaceName" $node.name."#text" `
        | Add-Member -PassThru NoteProperty "NamespaceDescription" $node.description."#text" `
        | Add-Member -PassThru NoteProperty "NamespaceLastChanged" $node.lastChanged `
        | Add-Member -PassThru NoteProperty "NamespaceLastChangedBy" $node.lastChangedBy `
        | Add-Member -PassThru NoteProperty "QSName" $QSNode.name."#text" `
        | Add-Member -PassThru NoteProperty "QSDataSource" $QSNode.definition.dbQuery.sources.dataSourceRef `
        | Add-Member -PassThru NoteProperty "QSSQL" $rawSql `
        | Add-Member -PassThru NoteProperty "QSModelQuery" $modelQuery `
        | Add-Member -PassThru NoteProperty "QSSourceTable" $sourceTable `
        | Add-Member -PassThru NoteProperty "QSTableType" $QSNode.definition.dbQuery.tableType `
        | Add-Member -PassThru NoteProperty "QSLastChanged" $QSNode.lastChanged `
        | Add-Member -PassThru NoteProperty "QSLastChangedBy" $QSNode.lastChangedBy `
		| Add-Member -PassThru NoteProperty "ProjectName" $ProjectName `
        | Add-Member -PassThru NoteProperty "SourceFileId" $FileId
    )
    return $result
}

# Process Namespaces
# $node: root namespace / folder
function Process-NamespaceNode($node) {
    $results = @()
    if ($node) {
        #Process QuerySubjects
        $querySubjects = $node.querySubject
        if($querySubjects){
            ForEach ($qs in $querySubjects){
                $results += Process-QSNode -node $node -QSNode $qs
            }
        }
        #Process SubNamespaces
        $childNamespaces = $node.namespace
        if( $childNamespaces){
            ForEach ($cNamespace in $childNamespaces){
                $childResults = Process-NamespaceNode -node $cNamespace
                $results += $childResults
            }
        }
        #Process SubFolders
        $ChildFolders = $node.folder
        if($ChildFolders){
            ForEach ($sf in $ChildFolders){
                $childFResults = Process-NamespaceNode -node $sf
                $results += $childFResults
            }
        }
    }

    return $results
}

# Process the Root Namespace and Save Data
# $node: root namespace / folder
function ExtractQSData($RootNamespace) {
    $QSData = Process-NamespaceNode -node $RootNamespace
    $DestFileName = $QuerySubjectDir + $FileId + ".csv"

    $QSData | Select NamespaceName, NamespaceDescription, NamespaceLastChanged, NamespaceLastChangedBy, QSName, QSLastChanged, QSLastChangedBy, QSSQL, QSModelQuery, QSSourceTable, QSTableType, QSDataSource, ProjectName, SourceFileId `
    | Export-Csv -Path $DestFileName -NoTypeInformation
}
