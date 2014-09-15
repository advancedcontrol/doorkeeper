function(doc) {
  if(doc.type === 'dk_at') {
    emit([doc.token]);
  }
}
