# Combat motion study

The motion goal is readable, grounded hand-to-hand combat with visible preparation, contact and recovery. The current build is a prototype; its character rig, enemy reactions and paired finishers still need dedicated animation direction and playtesting before they can approach the owner's Sifu, Sleeping Dogs and Acts of Blood references.

## References applied

- [Sifu animation director Kevin Roger's interview](https://www.pointnthink.fr/en/interview-kevin-roger-sifu/) describes hand-posed gameplay animation and selective capture for takedowns, followed by substantial reworking. This is the quality bar for authored strike silhouettes and paired reactions, rather than evidence that more raw clips alone will solve the problem.
- [Epic Games' Motion Warping documentation](https://dev.epicgames.com/documentation/unreal-engine/motion-warping-in-unreal-engine) explains aligning a source motion with a target over a defined motion window. Our implementation is in Godot, not Unreal: the bake records a source limb's contact position, and the controller calculates the opponent-relative approach before the strike. It shifts the fighter during a visible guarded step, then plays the planted source strike through contact.
- [CMU Graphics Lab's motion capture database](https://mocap.cs.cmu.edu/) supplies the bundled subject 135 karate takes. Take 02 contributes a straight with a raised-knee silhouette and left/right evasions; take 09 supplies the stepping strike. The original ASF/AMC files, checksums, usage notice and local bake script are retained for repeatability; see [asset credits](THIRD_PARTY.md).

## Current implementation and limits

The active move graph has fourteen strikes, two paired three-contact counters and two clinch finishes. Captured clips retain whole-body turns and root travel, with foot-grounding corrections from the retargeted skeleton. Strike targeting uses the actual hand or foot position at its contact frame. A guarded approach step covers missing reach before the limb accelerates, rather than dragging the body through a planted punch. The two new slips use directional captured poses and collision-aware travel.

The [positioning review](qa/karate-positioning.mp4) is a scripted fixture capture showing an angled one-two, both karate straights and both slips. It is a visual review, not a claim of commercial-game animation quality or a live AI combat recording. The paired counter and clinch sequences remain assembled from single-performer motion and constraints; they need purpose-authored two-person animation, stronger hit reactions and a more expressive character rig. Godot tests cover contact timing, combo links, foot drift, paired-move cleanup and combat outcomes, but the owner must judge the feel in play.
