module.exports = {
  map: function(doc) {
    if (
      doc.publish &&
      "block" in doc &&
      "actions" in doc.block &&
      Array.isArray(doc.block.actions) &&
      "label" in doc.block &&
      "portal" in doc &&
      Array.isArray(doc.portal)
    ) {
      doc.portal.forEach(function(portal) {
        doc.block.actions.forEach(function(action) {
          emit([portal, action, doc.block.label], null);
        });
      });
    }
  }
};
