import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'art.dart';

/// Effetti sonori. Il file è `assets/audio/sfx/<nome>.ogg`: finché manca,
/// il gioco resta muto (nessun errore). L'elenco completo con le istruzioni
/// per chi li produce è in `lista-suoni.md`.
enum Sfx {
  // Interfaccia
  tap('ui_tap'),
  tab('ui_tab'),
  confirm('ui_confirm'),
  locked('ui_locked'),
  // Allenamento
  repGood('rep_good'),
  repPerfect('rep_perfect'),
  repPoor('rep_poor'),
  countdownTick('countdown_tick'),
  countdownGo('countdown_go'),
  setDone('set_done'),
  switchLeg('switch_leg'),
  restTick('rest_tick'),
  restEnd('rest_end'),
  movePhone('move_phone'),
  // Combattimento
  heroHit('hero_hit'),
  heroCrit('hero_crit'),
  heroBounce('hero_bounce'),
  enemyHit('enemy_hit'),
  enemyDie('enemy_die'),
  victory('victory'),
  youDied('you_died'),
  fled('fled'),
  // Progressi e bottino
  levelUp('level_up'),
  skillUp('skill_up'),
  questDone('quest_done'),
  chestOpen('chest_open'),
  // Forgia, raccolta, mercato
  craftTick('craft_tick'),
  craftCancel('craft_cancel'),
  craftCarpentry('craft_carpentry'),
  craftFurnace('craft_furnace'),
  craftAnvil('craft_anvil'),
  craftEnchant('craft_enchant'),
  gatherWood('gather_wood'),
  gatherOre('gather_ore'),
  buy('buy'),
  sell('sell'),
  // Apertura
  splashReveal('splash_reveal'),
  splashRing('splash_ring'),
  splashHelm('splash_helm');

  const Sfx(this.file);
  final String file;
  String get path => 'assets/audio/sfx/$file.ogg';
}

/// Musiche in loop, una per sezione: `assets/audio/music/<nome>.ogg`.
enum Music {
  home('music_home'),
  training('music_training'),
  gathering('music_gathering'),
  forge('music_forge'),
  market('music_market'),
  arena('music_arena'),
  guild('music_guild'),
  combat('music_combat'),
  boss('music_boss');

  const Music(this.file);
  final String file;
  String get path => 'assets/audio/music/$file.ogg';
}

class Sound {
  static bool sfxOn = true;
  static bool musicOn = true;
  static bool voiceOn = true;

  static final _pool = <AudioPlayer>[];
  static var _next = 0;
  static AudioPlayer? _music;
  static AudioPlayer? _voice;
  static Music? _current;
  static final _stack = <Music?>[];

  static Future<void> init() async {
    try {
      final p = await SharedPreferences.getInstance();
      sfxOn = p.getBool('sfx_on') ?? true;
      musicOn = p.getBool('music_on') ?? true;
      voiceOn = p.getBool('voice_on') ?? true;
    } catch (_) {}
  }

  static Future<void> setSfx(bool v) async {
    sfxOn = v;
    (await SharedPreferences.getInstance()).setBool('sfx_on', v);
  }

  static Future<void> setVoice(bool v) async {
    voiceOn = v;
    if (!v) _voice?.stop();
    (await SharedPreferences.getInstance()).setBool('voice_on', v);
  }

  static Future<void> setMusic(bool v) async {
    musicOn = v;
    (await SharedPreferences.getInstance()).setBool('music_on', v);
    final m = _current;
    _current = null;
    if (v) {
      music(m);
    } else {
      _music?.stop();
    }
  }

  static String _asset(String path) => path.substring('assets/'.length);

  /// Suona un effetto se il file c'è; più effetti possono sovrapporsi.
  static void play(Sfx s, {double volume = 1}) {
    if (!sfxOn || !Art.has(s.path)) return;
    try {
      if (_pool.length < 6) _pool.add(AudioPlayer()..setReleaseMode(ReleaseMode.stop));
      final p = _pool[_next++ % _pool.length];
      p.stop().then((_) => p.play(AssetSource(_asset(s.path)), volume: volume));
    } catch (e) {
      debugPrint('Sound: $e');
    }
  }

  /// Cambia la musica di sottofondo (null la ferma). Se è già quella, non
  /// riparte da capo.
  static void music(Music? m) {
    if (m == _current) return;
    _current = m;
    try {
      if (m == null || !musicOn || !Art.has(m.path)) {
        _music?.stop();
        return;
      }
      _music ??= AudioPlayer()..setReleaseMode(ReleaseMode.loop);
      _music!.play(AssetSource(_asset(m.path)), volume: 0.45);
    } catch (e) {
      debugPrint('Sound: $e');
    }
  }

  /// Musica temporanea (combattimento, boss): [popMusic] torna alla
  /// precedente.
  static void pushMusic(Music m) {
    _stack.add(_current);
    music(m);
  }

  static void popMusic() => music(_stack.isEmpty ? null : _stack.removeLast());

  /// Una battuta del Comandante Reynard: `assets/audio/voice/<id>.ogg`.
  static bool voice(String id) {
    final path = 'assets/audio/voice/$id.ogg';
    if (!voiceOn || !Art.has(path)) return false;
    try {
      _voice ??= AudioPlayer();
      _voice!.stop().then((_) => _voice!.play(AssetSource(_asset(path))));
      return true;
    } catch (e) {
      debugPrint('Sound: $e');
      return false;
    }
  }

  static void stopVoice() => _voice?.stop();
}
