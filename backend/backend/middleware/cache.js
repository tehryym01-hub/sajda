import NodeCache from 'node-cache';

const cache = new NodeCache({ checkperiod: 120 });

const cacheMiddleware = (duration) => {
  return (req, res, next) => {
    const key = req.originalUrl || req.url;
    const cachedResponse = cache.get(key);

    if (cachedResponse) {
      return res.json(cachedResponse);
    }

    const originalJson = res.json.bind(res);
    res.json = (body) => {
      cache.set(key, body, duration);
      originalJson(body);
    };
    next();
  };
};

export { cache, cacheMiddleware };
