# Kanto in Motion v1.6.5 scope

Compared with v1.6.4, v1.6.5 focuses on optional 1025Dex battle compatibility and small presentation/UI cleanup.

- Routes Game3 battle sprites by National Dex ownership: KIM HD animated art for #001–386 and 1025Dex art for #387–1025 when the optional mod is present.
- Prevents duplicate KIM/1025Dex battler layers by keeping KIM as the final Game3 sprite router.
- Places 1025Dex fallback battlers on KIM's battle floor and applies KIM ground-contact shadows.
- Includes the confirmed opponent/front grounding adjustment for post-Gen3 fallback sprites.
- Moves Gen 2 mobile option-screen scroll arrows into a dedicated right-side gutter.
- Hides the Game3 **KIM ASSETS** Start Menu entry once the shared HD cache validates as healthy.

The persistent external HD asset cache remains in place, and normal KIM code updates do not require users to redownload an already-installed healthy pack.
