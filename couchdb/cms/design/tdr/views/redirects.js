module.exports = {
  map: function(doc) {
    if (doc.type == "redirect") {
      doc.portal.forEach(function(portal) {
        emit([portal, doc.changed], null);
      });
    }
  }
};
