import '../domain/plan_template.dart';

PlanItem _r(int n, int sets, int reps, {bool side = false}) =>
    PlanItem.reps(n, sets, reps, perSide: side);
PlanItem _h(int n, int sets, int secs, {bool side = false}) =>
    PlanItem.hold(n, sets, secs, perSide: side);

/// The 13 plan templates. Together with the warm-up / cool-down pools in
/// [PlanBuilder] they use every one of the 98 unique exercise videos
/// (verified by test). Numbers refer to the exercise catalog.
final planTemplates = <PlanTemplate>[
  // ── Foundation plans ────────────────────────────────────────────────
  PlanTemplate(
    id: 'foundation-full-body',
    name: 'Full-Body Foundation',
    tagline: 'Start here',
    description: 'Push, pull, squat and brace. Simple movements that build the base for everything else.',
    focus: PlanFocus.fullBody,
    gear: {PlanGear.wall, PlanGear.chair, PlanGear.band},
    stages: [
      PlanStage(
        name: 'Foundation',
        level: PlanLevel.beginner,
        sessions: [
          PlanSession(
            name: 'Upper body & core',
            focus: PlanSessionFocus.upper,
            items: [
              _r(1, 3, 10),
              _r(2, 3, 8),
              _r(8, 3, 12),
              _r(6, 2, 8),
              _h(12, 3, 20),
            ],
          ),
          PlanSession(
            name: 'Legs & glutes',
            focus: PlanSessionFocus.lower,
            items: [
              _r(17, 3, 10),
              _r(18, 3, 10),
              _r(21, 3, 12),
              _r(20, 2, 6, side: true),
              _r(24, 3, 12),
            ],
          ),
          PlanSession(
            name: 'Full body',
            focus: PlanSessionFocus.full,
            items: [
              _r(3, 3, 6),
              _r(18, 3, 12),
              _r(10, 3, 8),
              _r(11, 3, 8),
              _r(21, 3, 12),
            ],
          ),
        ],
      ),
    ],
  ),
  PlanTemplate(
    id: 'core-control',
    name: 'Core Control',
    tagline: 'Brace & balance',
    description: 'Trunk stability and body tension — the quiet strength behind every skill.',
    focus: PlanFocus.core,
    gear: {},
    stages: [
      PlanStage(
        name: 'Core',
        level: PlanLevel.beginner,
        sessions: [
          PlanSession(
            name: 'Stability',
            focus: PlanSessionFocus.core,
            items: [
              _r(10, 3, 8),
              _r(11, 3, 8),
              _h(12, 3, 20),
              _h(13, 3, 20),
              _h(14, 2, 15, side: true),
            ],
          ),
          PlanSession(
            name: 'Body tension',
            focus: PlanSessionFocus.core,
            items: [
              _h(13, 3, 25),
              _h(14, 3, 20, side: true),
              _r(16, 3, 10),
              _h(15, 3, 15),
              _r(10, 2, 10),
            ],
          ),
        ],
      ),
    ],
  ),
  PlanTemplate(
    id: 'legs-and-glutes',
    name: 'Legs & Glutes',
    tagline: 'Lower-body strength',
    description: 'Squats, lunges and bridges that build strong, steady legs with no equipment.',
    focus: PlanFocus.legsGlutes,
    gear: {PlanGear.chair},
    strainsKnees: true,
    stages: [
      PlanStage(
        name: 'Legs & glutes',
        level: PlanLevel.beginner,
        sessions: [
          PlanSession(
            name: 'Squat & bridge',
            focus: PlanSessionFocus.lower,
            items: [
              _r(18, 3, 12),
              _r(19, 3, 8, side: true),
              _r(21, 3, 15),
              _r(23, 3, 8, side: true),
              _r(24, 3, 15),
            ],
          ),
          PlanSession(
            name: 'Single-leg strength',
            focus: PlanSessionFocus.lower,
            items: [
              _r(20, 3, 8, side: true),
              _r(22, 3, 8, side: true),
              _r(23, 3, 10, side: true),
              _r(17, 3, 12),
              _r(24, 3, 15),
            ],
          ),
        ],
      ),
    ],
  ),
  PlanTemplate(
    id: 'express-conditioning',
    name: 'Express Conditioning',
    tagline: 'Short & energizing',
    description: 'Quick full-body intervals to raise your heart rate when time is short.',
    focus: PlanFocus.conditioning,
    gear: {},
    stages: [
      PlanStage(
        name: 'Conditioning',
        level: PlanLevel.beginner,
        sessions: [
          PlanSession(
            name: 'Low-impact circuit',
            focus: PlanSessionFocus.full,
            items: [
              _h(25, 3, 40),
              _h(26, 3, 30),
              _h(114, 3, 30),
              _r(18, 3, 12),
              _h(12, 3, 20),
            ],
          ),
          PlanSession(
            name: 'Higher-energy circuit',
            focus: PlanSessionFocus.full,
            items: [
              _h(27, 3, 30),
              _h(29, 3, 25),
              _h(28, 3, 25),
              _r(30, 3, 6),
              _r(18, 3, 15),
            ],
          ),
        ],
      ),
    ],
  ),
  PlanTemplate(
    id: 'mobility-recovery',
    name: 'Mobility & Reset',
    tagline: 'Loosen up',
    description: 'Gentle mobility, stretching and slow breathing for rest days or whenever you feel stiff.',
    focus: PlanFocus.mobility,
    gear: {},
    stages: [
      PlanStage(
        name: 'Mobility',
        level: PlanLevel.beginner,
        sessions: [
          PlanSession(
            name: 'Upper body mobility',
            focus: PlanSessionFocus.upper,
            items: [
              _h(92, 2, 30),
              _h(93, 2, 30),
              _h(94, 2, 30),
              _h(95, 2, 30),
              _h(104, 2, 30),
            ],
          ),
          PlanSession(
            name: 'Lower body mobility',
            focus: PlanSessionFocus.lower,
            items: [
              _h(96, 2, 30),
              _h(97, 2, 30),
              _h(98, 2, 30, side: true),
              _h(99, 2, 30),
              _h(103, 2, 30),
            ],
          ),
          PlanSession(
            name: 'Wind down',
            focus: PlanSessionFocus.full,
            items: [
              _h(101, 2, 30),
              _h(102, 2, 40),
              _h(103, 2, 30),
              _h(104, 2, 30),
              _h(105, 2, 60),
            ],
          ),
        ],
      ),
    ],
  ),

  // ── Skill plans (foundation → build → master) ───────────────────────
  PlanTemplate(
    id: 'skill-push-up',
    name: 'Push-Up Progression',
    tagline: 'Wall to one-arm path',
    description:
        'From wall push-ups to archer push-ups, one controlled step at a time.',
    focus: PlanFocus.skill,
    skillId: 'push-up',
    gear: {PlanGear.wall, PlanGear.chair},
    strainsWrists: true,
    strainsShoulders: true,
    stages: [
      PlanStage(
        name: 'Foundation',
        level: PlanLevel.beginner,
        sessions: [
          PlanSession(
            name: 'Push',
            focus: PlanSessionFocus.upper,
            items: [_r(6, 2, 8), _r(1, 3, 10), _r(2, 3, 8), _r(3, 3, 6)],
          ),
          PlanSession(
            name: 'Support',
            focus: PlanSessionFocus.core,
            items: [_r(8, 3, 12), _h(12, 3, 20), _r(10, 3, 8), _r(21, 3, 12)],
          ),
        ],
      ),
      PlanStage(
        name: 'Build',
        level: PlanLevel.intermediate,
        sessions: [
          PlanSession(
            name: 'Push',
            focus: PlanSessionFocus.upper,
            items: [_r(3, 3, 8), _r(4, 4, 6), _r(43, 3, 6), _r(44, 3, 6)],
          ),
          PlanSession(
            name: 'Support',
            focus: PlanSessionFocus.core,
            items: [
              _r(7, 3, 8),
              _h(13, 3, 30),
              _h(14, 3, 20, side: true),
              _r(5, 3, 6),
            ],
          ),
        ],
      ),
      PlanStage(
        name: 'Master',
        level: PlanLevel.advanced,
        sessions: [
          PlanSession(
            name: 'Push',
            focus: PlanSessionFocus.upper,
            items: [
              _r(44, 4, 8),
              _r(45, 3, 4, side: true),
              _r(46, 3, 3, side: true),
            ],
          ),
          PlanSession(
            name: 'Support',
            focus: PlanSessionFocus.core,
            items: [_h(15, 3, 25), _h(9, 3, 20), _r(5, 3, 8)],
          ),
        ],
      ),
    ],
  ),
  PlanTemplate(
    id: 'skill-pull-up',
    name: 'Pull-Up Progression',
    tagline: 'Hang to full pull-up',
    description: 'Build back and grip strength with hangs, bands and negatives on the way to your first pull-up.',
    focus: PlanFocus.skill,
    skillId: 'pull-up',
    gear: {PlanGear.pullUpBar, PlanGear.band},
    strainsShoulders: true,
    stages: [
      PlanStage(
        name: 'Foundation',
        level: PlanLevel.beginner,
        sessions: [
          PlanSession(
            name: 'Hang & pull',
            focus: PlanSessionFocus.upper,
            items: [_r(31, 3, 6), _h(32, 3, 15), _h(33, 3, 15), _r(34, 3, 5)],
          ),
          PlanSession(
            name: 'Support',
            focus: PlanSessionFocus.core,
            items: [_r(8, 3, 12), _r(7, 3, 8), _r(10, 3, 8), _r(11, 3, 8)],
          ),
        ],
      ),
      PlanStage(
        name: 'Build',
        level: PlanLevel.intermediate,
        sessions: [
          PlanSession(
            name: 'Pull',
            focus: PlanSessionFocus.upper,
            items: [_r(34, 4, 5), _r(35, 3, 4), _r(36, 3, 3)],
          ),
          PlanSession(
            name: 'Support',
            focus: PlanSessionFocus.core,
            items: [_r(7, 4, 8), _h(13, 3, 30), _r(16, 3, 10)],
          ),
        ],
      ),
      PlanStage(
        name: 'Master',
        level: PlanLevel.advanced,
        sessions: [
          PlanSession(
            name: 'Pull',
            focus: PlanSessionFocus.upper,
            items: [_r(36, 4, 5), _r(37, 3, 3), _r(38, 3, 3, side: true)],
          ),
          PlanSession(
            name: 'Support',
            focus: PlanSessionFocus.core,
            items: [_h(15, 3, 30), _h(14, 3, 25, side: true), _h(9, 3, 25)],
          ),
        ],
      ),
    ],
  ),
  PlanTemplate(
    id: 'skill-chin-up',
    name: 'Chin-Up Progression',
    tagline: 'Biceps & back',
    description: 'Underhand-grip pulling, from assisted chin-ups to strict and paused reps.',
    focus: PlanFocus.skill,
    skillId: 'chin-up',
    gear: {PlanGear.pullUpBar, PlanGear.band},
    strainsShoulders: true,
    stages: [
      PlanStage(
        name: 'Foundation',
        level: PlanLevel.beginner,
        sessions: [
          PlanSession(
            name: 'Chin-up prep',
            focus: PlanSessionFocus.upper,
            items: [_h(76, 3, 15), _r(77, 3, 5), _r(78, 3, 4)],
          ),
          PlanSession(
            name: 'Support',
            focus: PlanSessionFocus.core,
            items: [_r(8, 3, 12), _r(10, 3, 8), _h(12, 3, 20)],
          ),
        ],
      ),
      PlanStage(
        name: 'Build',
        level: PlanLevel.intermediate,
        sessions: [
          PlanSession(
            name: 'Chin-up',
            focus: PlanSessionFocus.upper,
            items: [_r(79, 3, 4), _r(80, 3, 5), _r(81, 3, 3)],
          ),
          PlanSession(
            name: 'Support',
            focus: PlanSessionFocus.core,
            items: [_r(7, 3, 8), _h(13, 3, 30), _r(16, 3, 10)],
          ),
        ],
      ),
      PlanStage(
        name: 'Master',
        level: PlanLevel.advanced,
        sessions: [
          PlanSession(
            name: 'Chin-up',
            focus: PlanSessionFocus.upper,
            items: [_r(81, 4, 5), _r(82, 3, 3), _r(83, 3, 3)],
          ),
          PlanSession(
            name: 'Support',
            focus: PlanSessionFocus.core,
            items: [_h(15, 3, 30), _h(14, 3, 25, side: true)],
          ),
        ],
      ),
    ],
  ),
  PlanTemplate(
    id: 'skill-dips',
    name: 'Dip Progression',
    tagline: 'Arm power',
    description:
        'Support holds, assisted dips and controlled reps on parallel bars.',
    focus: PlanFocus.skill,
    skillId: 'dips',
    gear: {PlanGear.parallelBars, PlanGear.band},
    strainsShoulders: true,
    strainsWrists: true,
    stages: [
      PlanStage(
        name: 'Foundation',
        level: PlanLevel.beginner,
        sessions: [
          PlanSession(
            name: 'Support & lower',
            focus: PlanSessionFocus.upper,
            items: [_h(69, 3, 20), _h(70, 3, 15), _r(71, 3, 6), _r(72, 3, 5)],
          ),
          PlanSession(
            name: 'Push base',
            focus: PlanSessionFocus.upper,
            items: [_r(2, 3, 8), _r(6, 3, 8), _h(12, 3, 20)],
          ),
        ],
      ),
      PlanStage(
        name: 'Build',
        level: PlanLevel.intermediate,
        sessions: [
          PlanSession(
            name: 'Dip',
            focus: PlanSessionFocus.upper,
            items: [_r(72, 4, 5), _r(73, 3, 5), _r(74, 3, 3)],
          ),
          PlanSession(
            name: 'Push base',
            focus: PlanSessionFocus.upper,
            items: [_r(4, 3, 8), _r(43, 3, 6), _h(13, 3, 30)],
          ),
        ],
      ),
      PlanStage(
        name: 'Master',
        level: PlanLevel.advanced,
        sessions: [
          PlanSession(
            name: 'Dip',
            focus: PlanSessionFocus.upper,
            items: [_r(74, 4, 5), _r(75, 3, 3)],
          ),
          PlanSession(
            name: 'Push base',
            focus: PlanSessionFocus.upper,
            items: [_r(44, 3, 8), _h(15, 3, 25)],
          ),
        ],
      ),
    ],
  ),
  PlanTemplate(
    id: 'skill-pistol-squat',
    name: 'Pistol Squat Progression',
    tagline: 'Single-leg strength',
    description:
        'Supported single-leg squats to a full, controlled pistol squat.',
    focus: PlanFocus.skill,
    skillId: 'pistol-squat',
    gear: {PlanGear.chair},
    strainsKnees: true,
    stages: [
      PlanStage(
        name: 'Foundation',
        level: PlanLevel.beginner,
        sessions: [
          PlanSession(
            name: 'Single-leg',
            focus: PlanSessionFocus.lower,
            items: [
              _r(47, 3, 6, side: true),
              _r(48, 3, 5, side: true),
              _r(49, 3, 4, side: true),
            ],
          ),
          PlanSession(
            name: 'Leg base',
            focus: PlanSessionFocus.lower,
            items: [
              _r(18, 3, 12),
              _r(21, 3, 12),
              _r(24, 3, 12),
              _r(23, 3, 8, side: true),
            ],
          ),
        ],
      ),
      PlanStage(
        name: 'Build',
        level: PlanLevel.intermediate,
        sessions: [
          PlanSession(
            name: 'Single-leg',
            focus: PlanSessionFocus.lower,
            items: [
              _r(49, 3, 5, side: true),
              _r(50, 3, 4, side: true),
              _r(51, 3, 3, side: true),
            ],
          ),
          PlanSession(
            name: 'Leg base',
            focus: PlanSessionFocus.lower,
            items: [
              _r(19, 3, 8, side: true),
              _r(22, 3, 8, side: true),
              _r(24, 3, 15),
            ],
          ),
        ],
      ),
      PlanStage(
        name: 'Master',
        level: PlanLevel.advanced,
        sessions: [
          PlanSession(
            name: 'Single-leg',
            focus: PlanSessionFocus.lower,
            items: [
              _r(51, 4, 3, side: true),
              _r(52, 3, 3, side: true),
              _r(53, 3, 2, side: true),
            ],
          ),
          PlanSession(
            name: 'Leg base',
            focus: PlanSessionFocus.lower,
            items: [_r(22, 3, 10, side: true), _r(23, 3, 10, side: true)],
          ),
        ],
      ),
    ],
  ),
  PlanTemplate(
    id: 'skill-l-sit',
    name: 'L-Sit Progression',
    tagline: 'Core control on the bars',
    description: 'Tuck holds to a full L-sit, building core and shoulder support strength.',
    focus: PlanFocus.skill,
    skillId: 'l-sit',
    gear: {PlanGear.parallelBars},
    strainsWrists: true,
    stages: [
      PlanStage(
        name: 'Foundation',
        level: PlanLevel.beginner,
        sessions: [
          PlanSession(
            name: 'L-sit prep',
            focus: PlanSessionFocus.core,
            items: [_r(54, 3, 6), _r(55, 3, 6), _h(56, 3, 10)],
          ),
          PlanSession(
            name: 'Core base',
            focus: PlanSessionFocus.core,
            items: [_r(10, 3, 8), _h(12, 3, 20), _r(16, 3, 10)],
          ),
        ],
      ),
      PlanStage(
        name: 'Build',
        level: PlanLevel.intermediate,
        sessions: [
          PlanSession(
            name: 'L-sit',
            focus: PlanSessionFocus.core,
            items: [_r(57, 3, 6), _h(58, 3, 10, side: true), _h(59, 3, 8)],
          ),
          PlanSession(
            name: 'Core base',
            focus: PlanSessionFocus.core,
            items: [_h(13, 3, 30), _h(15, 3, 20), _r(16, 3, 12)],
          ),
        ],
      ),
      PlanStage(
        name: 'Master',
        level: PlanLevel.advanced,
        sessions: [
          PlanSession(
            name: 'L-sit',
            focus: PlanSessionFocus.core,
            items: [_h(59, 4, 10), _h(60, 4, 6)],
          ),
          PlanSession(
            name: 'Core base',
            focus: PlanSessionFocus.core,
            items: [_h(15, 3, 30), _h(14, 3, 25, side: true)],
          ),
        ],
      ),
    ],
  ),
  PlanTemplate(
    id: 'skill-handstand',
    name: 'Handstand Progression',
    tagline: 'Balance upside down',
    description: 'Wrist prep, wall work and balance drills toward a freestanding handstand.',
    focus: PlanFocus.skill,
    skillId: 'handstand',
    gear: {PlanGear.wall},
    strainsWrists: true,
    strainsShoulders: true,
    invertsNeck: true,
    stages: [
      PlanStage(
        name: 'Foundation',
        level: PlanLevel.beginner,
        sessions: [
          PlanSession(
            name: 'Prep',
            focus: PlanSessionFocus.upper,
            items: [_h(61, 2, 30), _h(62, 3, 20), _r(63, 3, 3)],
          ),
          PlanSession(
            name: 'Support',
            focus: PlanSessionFocus.upper,
            items: [_r(6, 3, 8), _h(12, 3, 20), _h(95, 2, 30)],
          ),
        ],
      ),
      PlanStage(
        name: 'Build',
        level: PlanLevel.intermediate,
        sessions: [
          PlanSession(
            name: 'Wall work',
            focus: PlanSessionFocus.upper,
            items: [_h(64, 3, 20), _h(65, 3, 20), _h(66, 3, 15)],
          ),
          PlanSession(
            name: 'Support',
            focus: PlanSessionFocus.upper,
            items: [_r(5, 3, 6), _h(15, 3, 20)],
          ),
        ],
      ),
      PlanStage(
        name: 'Master',
        level: PlanLevel.advanced,
        sessions: [
          PlanSession(
            name: 'Balance',
            focus: PlanSessionFocus.upper,
            items: [_h(66, 3, 20), _h(67, 3, 15), _h(68, 4, 10)],
          ),
          PlanSession(
            name: 'Support',
            focus: PlanSessionFocus.upper,
            items: [_r(5, 3, 8), _h(15, 3, 30)],
          ),
        ],
      ),
    ],
  ),
  PlanTemplate(
    id: 'skill-toes-to-bar',
    name: 'Toes-to-Bar Progression',
    tagline: 'Core & grip',
    description: 'Hanging knee raises to strict toes-to-bar with a strong, controlled core.',
    focus: PlanFocus.skill,
    skillId: 'toes-to-bar',
    gear: {PlanGear.pullUpBar},
    strainsShoulders: true,
    stages: [
      PlanStage(
        name: 'Foundation',
        level: PlanLevel.beginner,
        sessions: [
          PlanSession(
            name: 'Hanging core',
            focus: PlanSessionFocus.core,
            items: [_r(84, 3, 6), _r(85, 3, 6), _h(32, 3, 20)],
          ),
          PlanSession(
            name: 'Core base',
            focus: PlanSessionFocus.core,
            items: [_r(10, 3, 8), _h(12, 3, 20), _r(16, 3, 10)],
          ),
        ],
      ),
      PlanStage(
        name: 'Build',
        level: PlanLevel.intermediate,
        sessions: [
          PlanSession(
            name: 'Hanging core',
            focus: PlanSessionFocus.core,
            items: [_r(86, 3, 5), _r(87, 3, 5), _r(88, 3, 5)],
          ),
          PlanSession(
            name: 'Core base',
            focus: PlanSessionFocus.core,
            items: [_h(13, 3, 30), _h(15, 3, 20), _r(16, 3, 12)],
          ),
        ],
      ),
      PlanStage(
        name: 'Master',
        level: PlanLevel.advanced,
        sessions: [
          PlanSession(
            name: 'Hanging core',
            focus: PlanSessionFocus.core,
            items: [_r(89, 4, 4), _r(90, 4, 3)],
          ),
          PlanSession(
            name: 'Core base',
            focus: PlanSessionFocus.core,
            items: [_h(15, 3, 30), _h(14, 3, 25, side: true)],
          ),
        ],
      ),
    ],
  ),
];
