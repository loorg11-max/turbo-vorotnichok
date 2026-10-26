// Поддельный SDK Яндекс Игр для проверки сборки у себя: всё пишет в window.__yalog,
// облако хранит в localStorage («fake_cloud»), реклама «идёт» полторы секунды.
(function () {
	window.__yalog = [];
	const log = (s) => { window.__yalog.push(s); console.log('YA ' + s); };
	const ev = {};
	window.__yaev = ev;
	window.YaGames = { init: () => Promise.resolve({
		features: {
			LoadingAPI: { ready: () => log('ready') },
			GameplayAPI: { start: () => log('gameplay start'), stop: () => log('gameplay stop') },
		},
		on: (name, cb) => { ev[name] = cb; },
		getPlayer: () => Promise.resolve({
			getData: () => { log('getData'); return Promise.resolve({ save: localStorage.getItem('fake_cloud') || '' }); },
			setData: (d) => { log('setData ' + d.save.length); localStorage.setItem('fake_cloud', d.save); return Promise.resolve(); },
		}),
		adv: {
			showFullscreenAdv: ({ callbacks }) => { log('fullscreen'); callbacks.onOpen(); setTimeout(() => callbacks.onClose(true), 1500); },
			showRewardedVideo: ({ callbacks }) => {
				log('rewarded'); callbacks.onOpen();
				setTimeout(() => { callbacks.onRewarded(); callbacks.onClose(); }, 1500);
			},
		},
		leaderboards: { setScore: (n, v) => { log('score ' + n + ' ' + v); return Promise.resolve(); } },
	}) };
})();
