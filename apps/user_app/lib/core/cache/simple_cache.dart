import 'dart:collection';

class _CacheEntry<T> {
	final T value;
	final DateTime expiry;

	_CacheEntry({required this.value, required this.expiry});

	bool get isExpired => DateTime.now().isAfter(expiry);
}

class CacheManager {
	CacheManager._internal();
	static final CacheManager instance = CacheManager._internal();

	final Map<String, _CacheEntry<dynamic>> _cache = HashMap();

	T? get<T>(String key) {
		final entry = _cache[key];
		if (entry == null) return null;
		if (entry.isExpired) {
			_cache.remove(key);
			return null;
		}
		return entry.value as T;
	}

	void set<T>(String key, T value, Duration ttl) {
		_cache[key] = _CacheEntry<T>(value: value, expiry: DateTime.now().add(ttl));
	}

	Future<T> getOrFetch<T>(String key, Duration ttl, Future<T> Function() fetcher) async {
		final cached = get<T>(key);
		if (cached != null) return cached;
		final fetched = await fetcher();
		set<T>(key, fetched, ttl);
		return fetched;
	}

	void invalidate(String key) {
		_cache.remove(key);
	}

	void invalidateByPrefix(String prefix) {
		final keys = _cache.keys.where((k) => k.startsWith(prefix)).toList();
		for (final k in keys) {
			_cache.remove(k);
		}
	}

	void clear() {
		_cache.clear();
	}
}
