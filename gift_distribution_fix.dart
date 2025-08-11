// Fix for Gift Distribution section in DsrVisitScreen

// The issue is that the naration field is missing from the UI
// and the controllers are not properly updating the giftList

// Here's the corrected gift distribution section:

/*
// --- Gift Distribution (Dynamic List) ---
const _SectionHeader(
  icon: Icons.card_giftcard,
  label: 'Gift Distribution',
),
_FantasticCard(
  child: Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Gift Distribution',
            style: SparshTypography.bodyBold,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: isReadOnly ? null : () {
              print('Adding gift row...');
              addGiftRow();
            },
          ),
        ],
      ),
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: giftList.length,
        itemBuilder: (context, idx) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gift Type Dropdown
                isGiftTypeLoading
                    ? const LinearProgressIndicator()
                    : giftTypeError != null
                    ? Text(
                      giftTypeError!,
                      style: const TextStyle(color: Colors.red),
                    )
                    : DropdownButtonFormField<String>(
                      value: _dropdownValue(
                        giftList[idx]['giftType'],
                        giftTypeOptions,
                      ),
                      decoration: _fantasticInputDecoration(
                        'Gift Type',
                      ),
                      items:
                          giftTypeOptions
                              .map(
                                (e) => DropdownMenuItem<String>(
                                  value:
                                      e['value']?.toString() ??
                                      '',
                                  child: Text(
                                    '${e['text'] ?? e['value'] ?? ''} (${e['value'] ?? ''})',
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: isReadOnly ? null : (v) => setState(
                            () =>
                                giftList[idx]['giftType'] =
                                    v ?? '',
                          ),
                    ),
                const SizedBox(height: SparshSpacing.xs),
                
                // Quantity Field
                TextFormField(
                  controller:
                      giftQtyControllers.length > idx
                          ? giftQtyControllers[idx]
                          : null,
                  decoration: _fantasticInputDecoration('Qty'),
                  keyboardType: TextInputType.number,
                  readOnly: isReadOnly,
                  onChanged: (v) {
                    giftList[idx]['qty'] = v;
                    print('Gift $idx qty updated: $v');
                  },
                ),
                const SizedBox(height: SparshSpacing.xs),
                
                // MISSING NARATION FIELD - THIS IS THE FIX!
                TextFormField(
                  controller:
                      giftNarationControllers.length > idx
                          ? giftNarationControllers[idx]
                          : null,
                  decoration: _fantasticInputDecoration('Description/Naration'),
                  readOnly: isReadOnly,
                  onChanged: (v) {
                    giftList[idx]['naration'] = v;
                    print('Gift $idx naration updated: $v');
                  },
                ),
                const SizedBox(height: SparshSpacing.xs),

                // Delete Button
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: SparshTheme.errorRed,
                    ),
                    onPressed: isReadOnly ? null : () {
                      print('Removing gift row at index $idx');
                      removeGiftRow(idx);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ],
  ),
),
*/

// Also need to add debug logging in the submit form:
/*
// Filter and validate gift distribution data
final List<Map<String, dynamic>> giftDistributionData =
    giftList
        .where(
          (g) =>
              g['giftType'] != null &&
              g['giftType']!.isNotEmpty &&
              g['qty'] != null &&
              g['qty']!.isNotEmpty,
        )
        .map(
          (g) => {
            'giftType': g['giftType']?.toString() ?? '',
            'qty': g['qty']?.toString() ?? '',
            'naration': g['naration']?.toString() ?? '',
          },
        )
        .toList();

print('Gift distribution data to be sent: $giftDistributionData');
print('Number of gifts: ${giftDistributionData.length}');

// Add to DSR data
dsrData['GiftDistribution'] = giftDistributionData;
*/