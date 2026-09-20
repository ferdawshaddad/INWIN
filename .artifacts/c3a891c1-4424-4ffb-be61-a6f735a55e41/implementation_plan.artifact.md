# Implementation Plan - Custom Color Button Enhancements

The user wants to improve the "Add Color" (`+`) button in the product configurator.
1.  The `+` sign should always be black (it currently inherits the selected color).
2.  Once a custom color is added/picked, it should remain visible in the list of swatches ("always there").

## User Review Required

> [!IMPORTANT]
> The custom color will be remembered locally within the color picker row. If you switch to a different product category (e.g., from Cahier to Stylo), the custom color for that specific layer might reset to default if it wasn't saved, but for the current session, it will stay in the list of circles.

## Proposed Changes

### [Component] Gift Configurator UI

#### [MODIFY] [logo_positioner.dart](file:///C:/apps/inwin_app_v3/inwin_app/lib/features/gifts/presentation/widgets/logo_positioner.dart)

- **Update `_ColorPickerRowState`**:
    - Add a `Color? _customColor` state variable to track the most recent custom color selected for this specific product layer.
    - Update `initState` and `didUpdateWidget` to synchronize `_customColor` with `widget.selectedColor` if it's not in the standard palette.
    - Update the `build` method to include an extra `_ColorSwatchButton` for `_customColor` if it's not null.
- **Update `_CustomColorButton`**:
    - Hardcode the `Icons.add` color to `Colors.black` when not expanded (instead of using `selectedColor`).
- **Update `_ColorSwatchButton`**:
    - Ensure it handles generic colors correctly (it already does by taking a `Color`).

## Verification Plan

### Manual Verification
- Open any product configurator (e.g., Cahier).
- Click the `+` button to open the custom color picker.
- Notice the `+` icon is black.
- Select a custom color (e.g., a specific shade of pink).
- Verify that a new pink circle appears in the list of swatches.
- Select a standard color (e.g., "Noir").
- Verify that the pink circle **remains** in the list, allowing you to switch back to it easily.
- Close the picker and verify the `+` icon is still black.
