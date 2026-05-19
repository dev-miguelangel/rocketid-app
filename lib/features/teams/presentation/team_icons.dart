import 'package:flutter/material.dart';

/// Un icono disponible para el logo de un equipo: nombre estable (lo que se
/// guarda en el backend) + el [IconData] de Material para renderizarlo.
class TeamIcon {
  const TeamIcon(this.name, this.icon, this.label);

  final String name;
  final IconData icon;
  final String label;
}

/// Catálogo curado de iconos para logos de equipo. Todos verificados como
/// constantes válidas de la clase `Icons`.
const List<TeamIcon> teamIconCatalog = [
  TeamIcon('groups', Icons.groups, 'Equipo'),
  TeamIcon('diversity_3', Icons.diversity_3, 'Comunidad'),
  TeamIcon('hub', Icons.hub, 'Red'),
  TeamIcon('emoji_events', Icons.emoji_events, 'Trofeo'),
  TeamIcon('military_tech', Icons.military_tech, 'Medalla'),
  TeamIcon('shield', Icons.shield, 'Escudo'),
  TeamIcon('flag', Icons.flag, 'Bandera'),
  TeamIcon('star', Icons.star, 'Estrella'),
  TeamIcon('bolt', Icons.bolt, 'Rayo'),
  TeamIcon('local_fire_department', Icons.local_fire_department, 'Fuego'),
  TeamIcon('rocket_launch', Icons.rocket_launch, 'Cohete'),
  TeamIcon('pets', Icons.pets, 'Mascota'),
  TeamIcon('sports', Icons.sports, 'Deporte'),
  TeamIcon('sports_soccer', Icons.sports_soccer, 'Fútbol'),
  TeamIcon('sports_basketball', Icons.sports_basketball, 'Baloncesto'),
  TeamIcon('sports_volleyball', Icons.sports_volleyball, 'Voleibol'),
  TeamIcon('sports_baseball', Icons.sports_baseball, 'Béisbol'),
  TeamIcon('sports_football', Icons.sports_football, 'Fútbol americano'),
  TeamIcon('sports_tennis', Icons.sports_tennis, 'Tenis'),
  TeamIcon('sports_handball', Icons.sports_handball, 'Balonmano'),
  TeamIcon('sports_hockey', Icons.sports_hockey, 'Hockey'),
  TeamIcon('sports_golf', Icons.sports_golf, 'Golf'),
  TeamIcon('sports_cricket', Icons.sports_cricket, 'Críquet'),
  TeamIcon('sports_rugby', Icons.sports_rugby, 'Rugby'),
  TeamIcon('sports_martial_arts', Icons.sports_martial_arts, 'Artes marciales'),
  TeamIcon('sports_mma', Icons.sports_mma, 'MMA'),
  TeamIcon('sports_kabaddi', Icons.sports_kabaddi, 'Lucha'),
  TeamIcon('sports_esports', Icons.sports_esports, 'eSports'),
  TeamIcon('pool', Icons.pool, 'Natación'),
  TeamIcon('fitness_center', Icons.fitness_center, 'Gimnasio'),
  TeamIcon('directions_run', Icons.directions_run, 'Atletismo'),
  TeamIcon('pedal_bike', Icons.pedal_bike, 'Ciclismo'),
  TeamIcon('surfing', Icons.surfing, 'Surf'),
  TeamIcon('skateboarding', Icons.skateboarding, 'Skate'),
  TeamIcon('snowboarding', Icons.snowboarding, 'Snowboard'),
  TeamIcon('downhill_skiing', Icons.downhill_skiing, 'Esquí'),
  TeamIcon('ice_skating', Icons.ice_skating, 'Patinaje'),
  TeamIcon('kayaking', Icons.kayaking, 'Kayak'),
  TeamIcon('sailing', Icons.sailing, 'Vela'),
  TeamIcon('rowing', Icons.rowing, 'Remo'),
  TeamIcon('hiking', Icons.hiking, 'Senderismo'),
  TeamIcon('scuba_diving', Icons.scuba_diving, 'Buceo'),
  TeamIcon('kitesurfing', Icons.kitesurfing, 'Kitesurf'),
  TeamIcon('paragliding', Icons.paragliding, 'Parapente'),
];

final Map<String, IconData> _teamIconByName = {
  for (final t in teamIconCatalog) t.name: t.icon,
};

IconData resolveTeamIcon(String? name) =>
    _teamIconByName[name] ?? Icons.groups;

/// Resuelve el icono de un deporte por su nombre (p. ej. `sports_soccer`);
/// usa un icono genérico de deporte como respaldo.
IconData resolveSportIcon(String? name) =>
    _teamIconByName[name] ?? Icons.sports;

/// Paleta fija de colores de equipo (de `docs/curls/teams-curls.md`).
const List<String> kTeamColors = [
  '#E53935', '#D81B60', '#8E24AA', '#5E35B1',
  '#3949AB', '#1E88E5', '#039BE5', '#00ACC1',
  '#00897B', '#43A047', '#7CB342', '#C0CA33',
  '#FDD835', '#FFB300', '#FB8C00', '#F4511E',
];
