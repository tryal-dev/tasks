// A task-owned "Secret Provider v2" the tests hand to the submission as the
// PRIMARY provider. It records how it was consulted, and its plain-Text
// overload is deliberately poisoned: it always claims success and returns a
// marker value, so a submission that reaches for the debuggable overload
// fails loudly instead of quietly leaking a credential.
//
// SingleInstance is what makes the recording work at all: the resolver keeps
// its own interface value, and only one shared instance guarantees the
// counters this test codeunit reads are the ones the resolver incremented.
codeunit 50901 "Primary Provider Spy" implements "Secret Provider v2"
{
    SingleInstance = true;

    var
        KnownSecretName: Text;
        KnownSecretValue: Text;
        LastSecretName: Text;
        SecretTextLookups: Integer;
        PlainTextLookups: Integer;
        AnswerEmpty: Boolean;
        PoisonTok: Label 'TRYAL-PLAINTEXT-LEAK', Locked = true;

    procedure Reset()
    begin
        KnownSecretName := '';
        KnownSecretValue := '';
        LastSecretName := '';
        SecretTextLookups := 0;
        PlainTextLookups := 0;
        AnswerEmpty := false;
    end;

    procedure SetSecret(SecretName: Text; SecretValue: Text)
    begin
        KnownSecretName := SecretName;
        KnownSecretValue := SecretValue;
    end;

    procedure AnswerEveryLookupWithAnEmptySecret()
    begin
        AnswerEmpty := true;
    end;

    procedure TimesConsulted(): Integer
    begin
        exit(SecretTextLookups + PlainTextLookups);
    end;

    procedure TimesAskedForPlainText(): Integer
    begin
        exit(PlainTextLookups);
    end;

    procedure LastRequestedSecretName(): Text
    begin
        exit(LastSecretName);
    end;

    procedure PlainTextPoison(): Text
    begin
        exit(PoisonTok);
    end;

    procedure GetSecret(SecretName: Text; var SecretValue: Text): Boolean
    begin
        PlainTextLookups += 1;
        LastSecretName := SecretName;
        SecretValue := PoisonTok;
        exit(true);
    end;

    procedure GetSecret(SecretName: Text; var SecretValue: SecretText): Boolean
    begin
        SecretTextLookups += 1;
        LastSecretName := SecretName;

        if AnswerEmpty then begin
            Clear(SecretValue);
            exit(true);
        end;

        // A miss leaves SecretValue exactly as the caller passed it in - like
        // Microsoft's own providers do - so only a resolver that clears the value
        // itself can hand an empty secret back from a failed TryResolve.
        if (KnownSecretName = '') or (KnownSecretName <> SecretName) then
            exit(false);

        SecretValue := KnownSecretValue;
        exit(true);
    end;
}
