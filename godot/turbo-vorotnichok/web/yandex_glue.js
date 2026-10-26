// Яндекс Игры для «Турбо белого воротничка»: связка SDK Яндекса и игры (scripts/yandex.gd).
// Страница грузит /sdk.js (его отдаёт Яндекс), потом этот файл, потом движок Godot.
// Вне Яндекса /sdk.js нет, TurboYa.ok = false, и игра работает как обычная веб-версия.
(function () {
	// Звук глушим на уровне браузера: пока идёт реклама или вкладка скрыта, игра может стоять
	// (Godot не крутит кадры в скрытой вкладке), а звук должен молчать.
	const ctxs = [];
	const Native = window.AudioContext || window.webkitAudioContext;
	if (Native) {
		const Wrapped = function (opts) {
			const c = new Native(opts);
			ctxs.push(c);
			return c;
		};
		Wrapped.prototype = Native.prototype;
		window.AudioContext = Wrapped;
		window.webkitAudioContext = Wrapped;
	}

	const T = window.TurboYa = { ok: false, sdk: null, player: null, saveText: '', listener: null };
	const reasons = new Set(); // реклама, скрытая вкладка, пауза от Яндекса

	function hush(why, on) {
		const was = reasons.size > 0;
		if (on) reasons.add(why); else reasons.delete(why);
		const now = reasons.size > 0;
		if (now === was) return;
		ctxs.forEach((c) => { (now ? c.suspend() : c.resume()).catch(() => {}); });
		if (T.listener) {
			try { T.listener(now ? 'pause' : 'resume'); } catch (e) { console.warn(e); }
		}
	}
	T.hush = hush;
	document.addEventListener('visibilitychange', () => hush('hidden', document.hidden));
	// требование 1.3: без фокуса звук молчит
	window.addEventListener('blur', () => hush('blur', true));
	window.addEventListener('focus', () => hush('blur', false));
	// требования 1.6.1.8 и 1.6.2.7: никакого контекстного меню на игровом поле
	document.addEventListener('contextmenu', (e) => e.preventDefault());

	// До запуска движка: SDK, игрок и сохранение из облака. Дольше 5 секунд не ждём.
	T.boot = function () {
		if (typeof YaGames === 'undefined') return Promise.resolve();
		const init = YaGames.init().then((sdk) => {
			T.sdk = sdk;
			T.ok = true;
			try {
				sdk.on('game_api_pause', () => hush('sdk', true));
				sdk.on('game_api_resume', () => hush('sdk', false));
			} catch (e) { /* старый SDK без событий */ }
			return sdk.getPlayer({ scopes: false })
				.then((p) => { T.player = p; return p.getData(['save']); })
				.then((d) => { T.saveText = (d && d.save) || ''; })
				.catch((e) => console.warn('Яндекс: игрок', e));
		}).catch((e) => console.warn('Яндекс: SDK', e));
		return Promise.race([init, new Promise((r) => setTimeout(r, 5000))]);
	};

	T.listen = function (cb) { T.listener = cb; };
	T.ready = function () {
		try { T.sdk.features.LoadingAPI.ready(); } catch (e) { console.warn(e); }
	};
	T.gameplay = function (on) {
		try { const g = T.sdk.features.GameplayAPI; if (on) g.start(); else g.stop(); } catch (e) { /* нет в SDK */ }
	};
	T.save = function (text) {
		if (T.player) T.player.setData({ save: text }, false).catch((e) => console.warn('Яндекс: сохранение', e));
	};
	T.score = function (name, value) {
		try {
			const lb = T.sdk.leaderboards;
			const p = lb ? lb.setScore(name, value) : T.sdk.getLeaderboards().then((l) => l.setLeaderboardScore(name, value));
			Promise.resolve(p).catch(() => {});
		} catch (e) { /* таблицы нет */ }
	};
	T.fullscreen = function (done) {
		if (!T.ok) { if (done) done(false); return; }
		T.sdk.adv.showFullscreenAdv({ callbacks: {
			onOpen: () => hush('ad', true),
			onClose: (shown) => { hush('ad', false); if (done) done(!!shown); },
			onError: () => { hush('ad', false); if (done) done(false); },
		} });
	};
	T.rewarded = function (done) {
		if (!T.ok) { if (done) done(false); return; }
		let got = false;
		T.sdk.adv.showRewardedVideo({ callbacks: {
			onOpen: () => hush('ad', true),
			onRewarded: () => { got = true; },
			onClose: () => { hush('ad', false); if (done) done(got); },
			onError: () => { hush('ad', false); if (done) done(false); },
		} });
	};
})();
