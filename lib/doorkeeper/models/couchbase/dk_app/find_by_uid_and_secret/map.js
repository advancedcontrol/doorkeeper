function(doc) {
  if(doc.type === 'dk_app') {
    emit([doc.id, doc.secret]);
  }
}
