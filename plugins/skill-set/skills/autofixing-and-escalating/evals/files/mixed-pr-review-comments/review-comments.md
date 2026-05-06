# PR Review Comments — auth.js

**Reviewer:** @senior-dev

---

### Comment 1 (line 14)

This will crash if `user` is null. We just had a P0 last week from exactly this — when the DB returns no row, `findUser` returns `null` and `user.id` blows up. Add a null check before line 14.

---

### Comment 2 (line 22)

Consider using the strategy pattern for the different auth providers (password, oauth, magic-link). Right now they're all in one big `if/else` and it's getting unwieldy.

---

### Comment 3 (line 30)

Maybe extract the password validation into its own function? Just a thought — what do you think?
