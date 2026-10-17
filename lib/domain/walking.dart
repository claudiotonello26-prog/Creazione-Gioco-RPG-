/// La Camminata: i passi del giorno raccolgono legno e minerali (vedi
/// skills.dart). Oltre questo tetto i passi non contano: niente farming col
/// telefono in lavatrice.
const int dailyStepCap = 25000;

/// Traguardi di passi del giorno: una piccola ricompensa a ciascuno, a parte
/// la quest. 10000 è l'obiettivo vero e paga il 30% in più.
const List<int> stepMilestones = [2000, 4000, 6000, 10000];

int stepMilestoneRunes(int i) => i == stepMilestones.length - 1 ? 26 : 20;
