import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iron_oath/data/game_state.dart';
import 'package:iron_oath/domain/character.dart';
import 'package:iron_oath/domain/items.dart';
import 'package:iron_oath/domain/routine.dart';
import 'package:iron_oath/domain/exercise.dart';
import 'package:iron_oath/main.dart';
import 'package:iron_oath/online/hero_card.dart';
import 'package:iron_oath/online/local_guild.dart';
import 'package:shared_preferences/shared_preferences.dart';

LocalGuildService _local(Map<String, dynamic> store) => LocalGuildService(
      store: store,
      save: () {},
      me: () => HeroCard(name: 'Pietro', level: 4),
    );

void main() {
  test('il cavaliere pubblicato torna uguale e regge i dati sbagliati', () {
    final c = Character(name: 'Pietro', look: Appearance(female: true, hairStyle: 6))
      ..worn[ArmorSlot.chest] = 'gambeson';
    final card = HeroCard.tryParse(jsonDecode(jsonEncode(HeroCard.of(c).toJson())))!;
    expect(card.name, 'Pietro');
    expect(card.look.female, isTrue);
    expect(card.look.hairStyle, 6);
    expect(card.worn, {ArmorSlot.chest: 'gambeson'});
    final odd = HeroCard.tryParse({'n': 'X', 'worn': {'chest': 'boh'}, 'cape': 7})!;
    expect(odd.worn, isEmpty);
    expect(odd.cape, isNull);
    expect(HeroCard.tryParse('nulla'), isNull);
  });

  test('senza server: cerca una gilda, guardala, entra, esci', () async {
    final store = <String, dynamic>{};
    final g = _local(store);
    await g.refresh();
    expect(g.guild, isNull);
    expect(g.live, isFalse);
    await g.search('lame');
    final found = g.found.single;
    expect(found.name, 'Lame del Crepuscolo');
    final inside = await g.preview(found);
    expect(inside.map((m) => m.name), containsAll(['Isolde', 'Morgana']));
    expect(inside.every((m) => m.hero != null), isTrue);
    await g.join(found.id);
    expect(g.guild!.id, found.id);
    expect(g.members.any((m) => m.id == g.myId), isTrue);
    expect(g.isLeader, isFalse);
    // Si ricarica dal salvataggio uguale.
    final again = _local(jsonDecode(jsonEncode(store)) as Map<String, dynamic>);
    await again.refresh();
    expect(again.guild!.name, 'Lame del Crepuscolo');
    await g.leave();
    expect(g.guild, isNull);
    await expectLater(g.openSession(ExerciseId.pushUp), throwsException);
  });

  test('senza server: fonda, fai amicizia e porta in gilda', () async {
    LocalGuildService.answerDelay = const Duration(milliseconds: 10);
    final g = _local({});
    await g.createGuild('Ordine di Prova', 'Mai saltare le gambe');
    expect(g.isLeader, isTrue);
    expect(g.members.single.hero!.name, 'Pietro');
    // Uno ti ha già chiesto l'amicizia.
    final asked = g.friends.singleWhere((f) => f.state == 2);
    await g.acceptFriend(asked.id);
    expect(g.friendState(asked.id), 0);
    await g.addToGuild(asked.id);
    expect(g.members.map((m) => m.id), contains(asked.id));
    // Chiedi l'amicizia: il cavaliere risponde dopo un po'.
    await g.searchPlayers('rod');
    final rodrigo = g.players.single;
    await g.addFriend(rodrigo.id);
    expect(g.friendState(rodrigo.id), 1);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(g.friendState(rodrigo.id), 0);
    // Chi è in un'altra gilda non la lascia.
    await g.searchPlayers('isolde');
    final isolde = g.players.single.id;
    await g.addFriend(isolde);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await expectLater(g.addToGuild(isolde), throwsException);
    await g.removeFriend(isolde);
    expect(g.friendState(isolde), isNull);
    g.dispose();
  });

  testWidgets('la Gilda senza server: guardi dentro una gilda, entri, cerchi un cavaliere',
      (tester) async {
    LocalGuildService.answerDelay = const Duration(seconds: 1);
    SharedPreferences.setMockInitialValues({});
    final state = GameState();
    await state.load();
    state.acceptHealth();
    state.completeTest({
      for (final id in baseExercises) id: const TestResult(reps: 10, variantLevel: 0),
    });
    state.trainerEnabled = false;
    await tester.pumpWidget(IronOathApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Gilda'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Server non collegato'), findsWidgets);
    await tester.dragUntilVisible(
      find.text('Ordine della Brace'),
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    // A metà schermo, così non resta sotto la barra in basso.
    await Scrollable.ensureVisible(tester.element(find.text('Ordine della Brace')), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ordine della Brace'));
    await tester.pumpAndSettle();
    expect(find.text('Aldric'), findsOneWidget);
    await tester.tap(find.text('ENTRA NELLA GILDA'));
    await tester.pumpAndSettle();
    expect(find.text('ORDINE DELLA BRACE'), findsOneWidget);
    expect(state.socialLocal['guild'], 'g_brace');

    await tester.tap(find.text('Cavalieri'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Ott');
    await tester.tap(find.text('CERCA').last);
    await tester.pumpAndSettle();
    expect(find.text('Ottone'), findsOneWidget);
    await tester.tap(find.text('AMICIZIA'));
    await tester.pumpAndSettle();
    expect(find.text('Inviata'), findsOneWidget);
    // Il cavaliere di prova accetta dopo un po'.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Inviata'), findsNothing);
    expect(state.socialLocal['friends']['npc_13'], 0);
  });
}
