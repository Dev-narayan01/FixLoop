---
name: Fix Loop
colors:
  surface: '#FFF8F5'
  surface-dim: '#e7d7cd'
  surface-bright: '#fff8f5'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#FBF2EC'
  surface-container: '#F5EAE2'
  surface-container-high: '#EFE4DC'
  surface-container-highest: '#f0dfd5'
  on-surface: '#221a14'
  on-surface-variant: '#52443a'
  inverse-surface: '#382f28'
  inverse-on-surface: '#feeee3'
  outline: '#857469'
  outline-variant: '#D6C3B7'
  surface-tint: '#89511f'
  primary: '#6c3a08'
  on-primary: '#ffffff'
  primary-container: '#89511f'
  on-primary-container: '#ffd0ad'
  inverse-primary: '#ffb77e'
  secondary: '#735947'
  on-secondary: '#ffffff'
  secondary-container: '#ffdcc4'
  on-secondary-container: '#795f4c'
  tertiary: '#004e5c'
  on-tertiary: '#ffffff'
  tertiary-container: '#00687a'
  on-tertiary-container: '#98e4f9'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdcc3'
  primary-fixed-dim: '#ffb77e'
  on-primary-fixed: '#2f1500'
  on-primary-fixed-variant: '#6c3a08'
  secondary-fixed: '#ffdcc4'
  secondary-fixed-dim: '#e1c0a9'
  on-secondary-fixed: '#291709'
  on-secondary-fixed-variant: '#594231'
  tertiary-fixed: '#abedff'
  tertiary-fixed-dim: '#86d2e6'
  on-tertiary-fixed: '#001f26'
  on-tertiary-fixed-variant: '#004e5c'
  background: '#fff8f5'
  on-background: '#221a14'
  surface-variant: '#f0dfd5'
  text-secondary: '#51443B'
  dark-surface: '#19120D'
  dark-surface-container-low: '#201712'
  dark-surface-container: '#261E18'
  dark-surface-container-high: '#312822'
  dark-surface-container-highest: '#3C332D'
  dark-primary: '#FFB780'
  dark-primary-container: '#6C3A08'
  dark-on-primary-container: '#FFDCC4'
  dark-text: '#EFDFD6'
  dark-text-secondary: '#D6C3B7'
  dark-hairlines: '#51443B'
  status-reported-fill: '#DDE3EA'
  status-reported-text: '#3F4A58'
  status-assigned-fill: '#D3E4FF'
  status-assigned-text: '#1D4E89'
  status-in-progress-fill: '#FFE29A'
  status-in-progress-text: '#5B4300'
  status-resolved-fill: '#B4ECE0'
  status-resolved-text: '#00504A'
  status-verified-fill: '#C3EFB5'
  status-verified-text: '#1B5E20'
  status-rejected-fill: '#E5E1DE'
  status-rejected-text: '#4A4643'
typography:
  display:
    fontFamily: Bricolage Grotesque
    fontSize: 36px
    fontWeight: '600'
    lineHeight: 44px
  headline-lg:
    fontFamily: Bricolage Grotesque
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  headline-sm:
    fontFamily: Bricolage Grotesque
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  title-md:
    fontFamily: Atkinson Hyperlegible Next
    fontSize: 18px
    fontWeight: '700'
    lineHeight: 26px
  body-md:
    fontFamily: Atkinson Hyperlegible Next
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Atkinson Hyperlegible Next
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Atkinson Hyperlegible Next
    fontSize: 14px
    fontWeight: '700'
    lineHeight: 20px
  chip:
    fontFamily: Atkinson Hyperlegible Next
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
  code:
    fontFamily: Atkinson Hyperlegible Next
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1.5rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

# Design System: Fix Loop (Android app), Version 2
Campus complaint and resolution tracker.
Platform: Flutter, Material 3, Android portrait (390 x 844).

## 1. Color Palette & Roles
Seed: #613101 (Deep warm brown)
- Light Mode:
  - Background / Surface: #FFF8F5
  - Surface Container Low: #FBF2EC
  - Surface Container: #F5EAE2
  - Surface Container High: #EFE4DC
  - Primary: #89511F
  - On Primary: #FFFFFF
  - Primary Container: #FFDCC4
  - On Primary Container: #301400
  - Outline Variant: #D6C3B7
  - Text / On Surface: #221A14
  - Text Secondary: #51443B

- Dark Mode:
  - Background / Surface: #19120D
  - Surface Container Low: #201712
  - Surface Container / Dark Arch: #261E18
  - Surface Container High: #312822
  - Surface Container Highest: #3C332D
  - Primary: #FFB780
  - On Primary: #4E2600
  - Primary Container: #6C3A08
  - On Primary Container: #FFDCC4
  - Text / On Surface: #EFDFD6
  - Text Secondary: #D6C3B7
  - Hairlines: #51443B

- Status Tokens:
  - REPORTED (Received): Light fill #DDE3EA, text #3F4A58 | Dark fill #3A424D, text #C8D1DD (inbox)
  - ASSIGNED (With the team): Light fill #D3E4FF, text #1D4E89 | Dark fill #1E3A5F, text #AFCBFF (group)
  - IN_PROGRESS (Being fixed): Light fill #FFE29A, text #5B4300 | Dark fill #4D3B00, text #FFDF8F (build)
  - RESOLVED (Fixed, please check): Light fill #B4ECE0, text #00504A | Dark fill #00423B, text #9FF0E0 (task_alt)
  - VERIFIED (Closed): Light fill #C3EFB5, text #1B5E20 | Dark fill #1E4D22, text #A8E6A0 (check_circle)
  - REOPENED (Reopened): errorContainer / onErrorContainer (replay)
  - REJECTED (Not accepted): Light fill #E5E1DE, text #4A4643 | Dark fill #3B3633, text #CFC8C3 (block)

## 2. Typography
- Headlines & Titles: Bricolage Grotesque (semi-bold 600)
  - Display: 36 / 44 sp
  - Headline Large: 32 / 40 sp
  - Headline Small: 24 / 32 sp
- Body, Labels & UI: Atkinson Hyperlegible Next (or Inter)
  - Title: 18 / 26 sp, 700
  - Body: 16 / 24 sp, 400
  - Body Small: 14 / 20 sp, 400
  - Label: 14 / 20 sp, 700
  - Chip: 12 / 16 sp, 700
  - Code: 14 / 20 sp, tabular
- Sentence case only. No all-caps. No tiny text below 14 sp (chips/nav 12 sp).

## 3. Signature Elements & Rules
- The Loop Moon in the Arch:
  - Fully rounded top arch with 28 dp bottom corners.
  - Light mode arch: #FFDCC4. Dark mode arch: #261E18 with subtle stars.
  - Moon phases represent progress: crescent (reported), half (in progress), ~88% (fixed/check), full disc with sealed ring (closed).
- Layout:
  - Android phone portrait 390 x 844. 24 dp margins. 35%+ empty space. Max 40 words UI text.
  - Buttons: Pill shape 48 dp high (Staff 56 dp, 16 dp radius). Group with space and hairlines, not cards.
