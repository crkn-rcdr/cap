module.exports = {
  map: function(doc) {
    if (
      !("block" in doc) &&
      doc.type != "redirect" &&
      Array.isArray(doc["portal"])
    ) {
      doc["portal"].forEach(function(portal) {
        emit([portal, doc["changed"]], null);
      });
    }
  }
};
