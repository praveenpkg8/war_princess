# 🎮 Game Design Document: Masked Escape
**Jam Scope:** 24 Hours
**Genre:** 2D Top-Down Stealth Survival
**Engine:** Unity / Godot / Unreal (Recommended: 2D)

---

## 1. 📌 Executive Summary
**Masked Escape** is a high-tension stealth game where the player infiltrates a toxic military camp to rescue their partner. The core twist is the **Mask Mechanic**: The air is poisonous. The player’s gas mask filter constantly degrades. If it fails, the player coughs, creating noise that alerts enemies. Survival depends on killing guards to steal their masks before your air runs out.

---

## 2. 🎯 Core Mechanics & Rules

### A. The Mask System (The "Hook")
* **The Timer:** The player has a "Filter Health" bar (approx. 45-60 seconds duration).
* **Degradation:** Depletes constantly. Depletes faster if sprinting (optional, if time permits).
* **Failure State (Mask breaks):**
    * Screen turns green/hazy.
    * **Audio:** Loud coughing loops.
    * **Detection:** Coughing generates a "Noise Circle" (Sound Collider). Any enemy touching this circle instantly detects the player.
* **Restoration:** Looting a dead guard restores Filter Health to 100%.

### B. Stealth & Visibility
* **Vision Cones:** Enemies have a visible cone of light. Walking into it triggers detection.
* **Noise Circles:** Running or Coughing spawns a temporary invisible circle around the player. If an enemy overlaps with it, they investigate.
* **Light/Shadow:** (Scope Cut) Don't implement complex light baking. Use simple sprite overlays to indicate "Hidden" vs "Visible."

### C. Combat (The Knife)
* **Lethality:** One-hit kill.
* **Condition:** Must be performed from **behind** or **flank** (not from inside the enemy vision cone).
* **Input:** Press `SPACE` or `LMB` when near enemy.
* **Result:** Enemy drops to the ground instantly. A "Mask Loot" icon appears over the body.

### D. Interacting / Pickup (Addressing your Question)
* **Input:** Press `E` (Keyboard) or `West Button` (Controller).
* **Process:**
    1.  Player stands over dead guard.
    2.  UI Prompt appears: *"Press E to Swap Filter"*.
    3.  Player holds button for 0.5s (creates tension).
    4.  **Feedback:** sound of gas hiss + filter bar refills.
* **Why Manual Pickup?** Auto-pickup is messy. Manual pickup forces the player to stop moving for a split second, adding risk and tension.

---

## 3. 🧠 AI Architecture (Addressing your Question)

**Selected System: Finite State Machine (FSM)**
*Why?* For a 1-day jam, Goal-Oriented Action Planning (GOAP) is too over-engineered and Behavior Trees can be tricky to set up quickly. An FSM is easy to code with a simple `switch` statement.

### The 3 AI States:
1.  **State: PATROL (Green)**
    * Enemy walks between defined Waypoints.
    * Loops endlessly.
    * Vision Cone is active.
2.  **State: INVESTIGATE (Yellow)**
    * **Trigger:** Player creates a "Noise" (Cough or Run) within range.
    * **Action:** Enemy stops patrol, walks to the location where the sound happened, looks around for 3 seconds.
    * **Exit:** If nothing found, return to nearest Patrol waypoint.
3.  **State: CHASE/ATTACK (Red)**
    * **Trigger:** Player steps inside Vision Cone.
    * **Action:** Enemy runs directly at player.
    * **End Game:** If Enemy collides with Player -> Game Over.

---

## 4. 🕹️ Controls (Simple)
| Action | Keyboard | Controller |
| :--- | :--- | :--- |
| **Move** | WASD | Left Stick |
| **Kill / Attack** | Spacebar | 'X' / Square |
| **Interact / Loot Mask** | E | 'A' / Cross |
| **Sprint (Optional)** | Shift | L Trigger |

---

## 5. 🗺️ Level Design & Progression
* **Setting:** Oppressive industrial camp (Grey/Brown palette).
* **Fog:** Use a green vignette overlay to sell the "Toxic Gas" atmosphere without expensive particle effects.
* **Layout Strategy (Hub & Key):**
    1.  **Start:** Safe area.
    2.  **Obstacle:** Locked Gate.
    3.  **Risk:** Player sees Keycard on a table, but 2 guards are patrolling it.
    4.  **Climax:** Retrieve Keycard -> Open Gate -> Find Boyfriend's Cell.
* **Narrative:** Minimal text. Use environmental storytelling (e.g., "Quarantine Zone" signs).

---

## 6. 🎨 Asset Priorities (24-Hour Plan)

### Audio (High Priority - 50% of the game feel)
* **Coughing:** Needs to sound painful and wet.
* **Heartbeat:** Increases speed as mask filter gets low.
* **Alert Sound:** A sharp "Violin screech" or "Radio static" when an enemy spots you.

### Visuals (Keep it Abstract)
* **Player:** Circle with a distinct color or simple sprite.
* **Enemy:** Circle with a distinct color + Light Cone sprite.
* **Mask UI:** A simple decreasing bar on screen.

---

## 7. 💻 Development Checklist (Order of Operations)

1.  **Hour 0-2:** Player Movement + Wall Collisions.
2.  **Hour 2-4:** Enemy Patrol (Move point A to B).
3.  **Hour 4-6:** **The Vision Cone.** (If Player enters Trigger Zone -> Game Over).
4.  **Hour 6-8:** **The Mask Timer.** (Timer counts down; triggers Cough sound when 0).
5.  **Hour 8-10:** **Sound Detection.** (If Coughing AND Enemy near -> Enemy moves to Player).
6.  **Hour 10-12:** Kill & Loot implementation.
7.  **Hour 12-18:** Level Building & Polish.
8.  **Hour 18+:** Juice (Screen shake, lighting, sound mixing).