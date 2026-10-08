import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/time_parser.dart';
import '../../../data/models/circuit.dart';
import '../../../data/models/circuit_group_session.dart';
import '../../../data/models/guide_desk.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_time_picker.dart';
import '../../widgets/primary_button.dart';

/// Lo que el guía llena para publicar o corregir una salida.
typedef DepartureDraft = ({
  String circuitId,
  DateTime date,
  String startTime,
  int capacity,
  bool transportIncluded,
  String note,
});

/// El marco de las hojas del guía: título, cerrar y el contenido con scroll
/// que sube con el teclado.
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: AppTextStyles.title)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: context.l10n.commonClose,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<T?> _showSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => child,
  );
}

int? _amount(String text) => int.tryParse(text.replaceAll(RegExp(r'\D'), ''));

// ── Postularse ──────────────────────────────────────────────────────────────

/// Pide el precio (sin pasar del tope) y un mensaje para el turista.
Future<({int fee, String message})?> showApplySheet(
  BuildContext context,
  OpenRequest request,
) => _showSheet(context, _ApplySheet(request: request));

class _ApplySheet extends StatefulWidget {
  const _ApplySheet({required this.request});

  final OpenRequest request;

  @override
  State<_ApplySheet> createState() => _ApplySheetState();
}

class _ApplySheetState extends State<_ApplySheet> {
  final _form = GlobalKey<FormState>();
  late final _fee = TextEditingController(
    text: widget.request.maxFee?.toString() ?? '',
  );
  final _message = TextEditingController();

  @override
  void dispose() {
    _fee.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final request = widget.request;
    final maxFee = request.maxFee;
    return Form(
      key: _form,
      child: _SheetFrame(
        title: l10n.guideDeskApplyTitle,
        children: [
          Text(
            Formatters.facts([
              request.itineraryTitle,
              Formatters.weekdayDate(request.date),
              Formatters.timeText(request.startTime),
              Formatters.people(request.groupSize),
            ]),
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 16),
          AppTextField(
            hint: l10n.guideDeskApplyFee,
            helper: maxFee == null
                ? null
                : l10n.guideDeskApplyMaxFee(Formatters.currency(maxFee)),
            controller: _fee,
            keyboardType: TextInputType.number,
            validator: (value) {
              final fee = _amount(value ?? '');
              if (fee == null || fee < 1) return l10n.guideDeskApplyFeeMissing;
              if (maxFee != null && fee > maxFee) {
                return l10n.guideDeskApplyMaxFee(Formatters.currency(maxFee));
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          AppTextField(
            hint: l10n.guideDeskApplyMessage,
            controller: _message,
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.multiline,
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: l10n.guideDeskApply,
            onPressed: () {
              if (!(_form.currentState?.validate() ?? false)) return;
              Navigator.of(
                context,
              ).pop((fee: _amount(_fee.text)!, message: _message.text.trim()));
            },
          ),
        ],
      ),
    );
  }
}

// ── Salidas ─────────────────────────────────────────────────────────────────

/// Publica una salida (con [circuits] para elegir) o corrige [editing]: en
/// una salida publicada solo cambian el cupo, el transporte y la nota.
Future<DepartureDraft?> showDepartureSheet(
  BuildContext context, {
  List<Circuit> circuits = const [],
  CircuitGroupSession? editing,
}) =>
    _showSheet(context, _DepartureSheet(circuits: circuits, editing: editing));

class _DepartureSheet extends StatefulWidget {
  const _DepartureSheet({required this.circuits, required this.editing});

  final List<Circuit> circuits;
  final CircuitGroupSession? editing;

  @override
  State<_DepartureSheet> createState() => _DepartureSheetState();
}

class _DepartureSheetState extends State<_DepartureSheet> {
  final _form = GlobalKey<FormState>();
  late String? _circuitId =
      widget.editing?.circuitId ?? widget.circuits.firstOrNull?.id;
  late DateTime _date =
      widget.editing?.date ?? DateTime.now().add(const Duration(days: 1));
  late String _startTime = widget.editing?.startTime ?? '8:00 a.m.';
  late int _capacity = widget.editing?.capacity ?? 10;
  late bool _transport = widget.editing?.transportIncluded ?? false;
  late final _note = TextEditingController(text: widget.editing?.note ?? '');

  bool get _isEditing => widget.editing != null;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      locale: Localizations.localeOf(context),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final minutes = TimeParser.minutesOfDay(_startTime) ?? 8 * 60;
    final picked = await showAppTimePicker(
      context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      helpText: context.l10n.guideDeskDepartureTime,
    );
    if (picked != null) {
      setState(
        () =>
            _startTime = Formatters.dataTime(picked.hour * 60 + picked.minute),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final editing = widget.editing;
    return Form(
      key: _form,
      child: _SheetFrame(
        title: _isEditing
            ? l10n.guideDeskDepartureEditTitle
            : l10n.guideDeskDeparturePublishTitle,
        children: [
          if (editing != null)
            Text(
              Formatters.facts([
                editing.circuitTitle,
                Formatters.weekdayDate(editing.date),
                Formatters.timeText(editing.startTime),
              ]),
              style: AppTextStyles.caption,
            )
          else ...[
            DropdownButtonFormField<String>(
              initialValue: _circuitId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.guideDeskDepartureCircuit,
              ),
              items: [
                for (final circuit in widget.circuits)
                  DropdownMenuItem(
                    value: circuit.id,
                    child: Text(
                      circuit.shortTitle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              validator: (value) =>
                  value == null ? l10n.guideDeskDepartureCircuitMissing : null,
              onChanged: (value) => setState(() => _circuitId = value),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month_outlined),
              title: Text(l10n.commonDate),
              trailing: Text(Formatters.shortDate(_date)),
              onTap: _pickDate,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: Text(l10n.guideDeskDepartureTime),
              trailing: Text(Formatters.timeText(_startTime)),
              onTap: _pickTime,
            ),
          ],
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.groups_outlined),
            title: Text(l10n.guideDeskDepartureCapacity),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: l10n.guideDeskLess,
                  onPressed: _capacity > 1
                      ? () => setState(() => _capacity--)
                      : null,
                ),
                Text('$_capacity', style: AppTextStyles.cardTitle),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: l10n.guideDeskMore,
                  onPressed: _capacity < 50
                      ? () => setState(() => _capacity++)
                      : null,
                ),
              ],
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.guideDeskDepartureTransport),
            value: _transport,
            onChanged: (value) => setState(() => _transport = value),
          ),
          AppTextField(
            hint: l10n.guideDeskDepartureNote,
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.multiline,
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: _isEditing
                ? l10n.commonSave
                : l10n.guideDeskDeparturePublish,
            onPressed: () {
              if (!(_form.currentState?.validate() ?? false)) return;
              Navigator.of(context).pop((
                circuitId: _circuitId ?? '',
                date: _date,
                startTime: _startTime,
                capacity: _capacity,
                transportIncluded: _transport,
                note: _note.text.trim(),
              ));
            },
          ),
        ],
      ),
    );
  }
}

// ── Cuenta bancaria y retiros ───────────────────────────────────────────────

/// Banco, titular, tipo y número de la cuenta donde recibe sus retiros.
Future<({String bank, String holder, String accountType, String number})?>
showBankAccountSheet(BuildContext context) =>
    _showSheet(context, const _BankAccountSheet());

class _BankAccountSheet extends StatefulWidget {
  const _BankAccountSheet();

  @override
  State<_BankAccountSheet> createState() => _BankAccountSheetState();
}

class _BankAccountSheetState extends State<_BankAccountSheet> {
  final _form = GlobalKey<FormState>();
  final _bank = TextEditingController();
  final _holder = TextEditingController();
  final _number = TextEditingController();
  String _type = 'ahorro';

  @override
  void dispose() {
    _bank.dispose();
    _holder.dispose();
    _number.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _form,
      child: _SheetFrame(
        title: l10n.guideFinanceAccountTitle,
        children: [
          Text(l10n.guideFinanceAccountWait, style: AppTextStyles.caption),
          const SizedBox(height: 12),
          AppTextField(
            hint: l10n.guideFinanceAccountBank,
            controller: _bank,
            textCapitalization: TextCapitalization.words,
            validator: (value) => (value ?? '').trim().length < 2
                ? l10n.guideFinanceAccountBankMissing
                : null,
          ),
          const SizedBox(height: 12),
          AppTextField(
            hint: l10n.guideFinanceAccountHolder,
            controller: _holder,
            textCapitalization: TextCapitalization.words,
            validator: (value) => (value ?? '').trim().length < 3
                ? l10n.guideFinanceAccountHolderMissing
                : null,
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'ahorro',
                label: Text(l10n.guideFinanceAccountSavings),
              ),
              ButtonSegment(
                value: 'corriente',
                label: Text(l10n.guideFinanceAccountChecking),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (value) => setState(() => _type = value.first),
          ),
          const SizedBox(height: 12),
          AppTextField(
            hint: l10n.guideFinanceAccountNumber,
            controller: _number,
            keyboardType: TextInputType.number,
            validator: (value) =>
                RegExp(r'^[\d\s-]{6,40}$').hasMatch((value ?? '').trim())
                ? null
                : l10n.guideFinanceAccountNumberInvalid,
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: l10n.commonSave,
            onPressed: () {
              if (!(_form.currentState?.validate() ?? false)) return;
              Navigator.of(context).pop((
                bank: _bank.text.trim(),
                holder: _holder.text.trim(),
                accountType: _type,
                number: _number.text.trim(),
              ));
            },
          ),
        ],
      ),
    );
  }
}

/// Cuánto retirar, sin pasar de [balance].
Future<int?> showPayoutSheet(BuildContext context, {required int balance}) =>
    _showSheet(context, _PayoutSheet(balance: balance));

class _PayoutSheet extends StatefulWidget {
  const _PayoutSheet({required this.balance});

  final int balance;

  @override
  State<_PayoutSheet> createState() => _PayoutSheetState();
}

class _PayoutSheetState extends State<_PayoutSheet> {
  final _form = GlobalKey<FormState>();
  late final _amountField = TextEditingController(text: '${widget.balance}');

  @override
  void dispose() {
    _amountField.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _form,
      child: _SheetFrame(
        title: l10n.guideFinancePayoutTitle,
        children: [
          Text(
            l10n.guideFinanceAvailable(Formatters.currency(widget.balance)),
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 12),
          AppTextField(
            hint: l10n.guideFinancePayoutAmount,
            controller: _amountField,
            keyboardType: TextInputType.number,
            validator: (value) {
              final amount = _amount(value ?? '');
              if (amount == null || amount < 1) {
                return l10n.guideFinancePayoutAmountMissing;
              }
              if (amount > widget.balance) {
                return l10n.guideFinanceAvailable(
                  Formatters.currency(widget.balance),
                );
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: l10n.guideFinancePayoutRequest,
            onPressed: () {
              if (!(_form.currentState?.validate() ?? false)) return;
              Navigator.of(context).pop(_amount(_amountField.text));
            },
          ),
        ],
      ),
    );
  }
}
