// Checks req.body / req.params against a zod schema before the controller
// runs. On success the parsed (trimmed, typed) values replace the originals,
// so controllers can trust them. On failure the error handler sends a 400.
const validate = (schemas) => (req, res, next) => {
  if (schemas.body) req.body = schemas.body.parse(req.body ?? {});
  if (schemas.params) req.params = schemas.params.parse(req.params ?? {});
  next();
};

module.exports = validate;
