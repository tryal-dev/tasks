codeunit 50900 "Work Stack Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PopReturnsTheMostRecentlyPushedValue()
    var
        WorkStack: Codeunit "Work Stack";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        LastPushed: Text;
        Popped: Text;
    begin
        // [SCENARIO] Pop hands back the value pushed last and removes it
        WorkStack.Push(Any.AlphabeticText(8));
        WorkStack.Push(Any.AlphabeticText(8));
        LastPushed := Any.AlphabeticText(8);
        WorkStack.Push(LastPushed);

        Assert.IsTrue(WorkStack.Pop(Popped), 'Expected Pop to return true while a value is stored');
        Assert.AreEqual(LastPushed, Popped, 'Expected Pop to hand out the value pushed last — the top of the stack is the back of the list');
        Assert.AreEqual(2, WorkStack.Count(), 'Expected Pop to remove the popped value, leaving the two earlier pushes stored');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PopsDrainInReverseOrderOfPushes()
    var
        WorkStack: Codeunit "Work Stack";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        First: Text;
        Second: Text;
        Third: Text;
    begin
        // [SCENARIO] Repeated Pops return the pushed values last in, first out
        First := Any.AlphabeticText(6);
        Second := Any.AlphabeticText(6);
        Third := Any.AlphabeticText(6);
        WorkStack.Push(First);
        WorkStack.Push(Second);
        WorkStack.Push(Third);

        Assert.AreEqual(Third + ',' + Second + ',' + First, DrainByPopping(WorkStack),
            'Expected repeated Pops to hand out the values in reverse order of pushing (last in, first out)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InterleavedPushesAndPopsKeepLifoOrder()
    var
        WorkStack: Codeunit "Work Stack";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        First: Text;
        Second: Text;
        Third: Text;
        PoppedInBetween: Text;
    begin
        // [SCENARIO] A Pop between pushes takes only the value on top at that moment
        First := Any.AlphabeticText(6);
        Second := Any.AlphabeticText(6);
        Third := Any.AlphabeticText(6);
        WorkStack.Push(First);
        WorkStack.Push(Second);
        WorkStack.Pop(PoppedInBetween);
        WorkStack.Push(Third);

        Assert.AreEqual(Third + ',' + First, DrainByPopping(WorkStack),
            'Expected pushing A and B, popping once, then pushing C to leave C on top of A — the Pop in between must take B and nothing else');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PopOnAnEmptyStackReturnsFalseWithoutAnError()
    var
        WorkStack: Codeunit "Work Stack";
        Assert: Codeunit Assert;
        Popped: Text;
    begin
        // [SCENARIO] Popping when nothing is stored reports false instead of raising
        Assert.IsFalse(WorkStack.Pop(Popped), 'Expected Pop on an empty stack to return false instead of raising an error — index 0 is not a valid list index');
        Assert.AreEqual(0, WorkStack.Count(), 'Expected Count to stay 0 after a Pop on an empty stack');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PopReturnsTrueForAStoredEmptyText()
    var
        WorkStack: Codeunit "Work Stack";
        Assert: Codeunit Assert;
        Popped: Text;
    begin
        // [SCENARIO] An empty text is a valid stored value; emptiness is signalled by the Boolean
        WorkStack.Push('');

        Assert.IsTrue(WorkStack.Pop(Popped), 'Expected Pop to return true for a stored empty text — emptiness of the stack is reported through the Boolean result, not through the value');
        Assert.AreEqual('', Popped, 'Expected the stored empty text to be handed out unchanged');
        Assert.AreEqual(0, WorkStack.Count(), 'Expected the stored empty text to be removed by Pop');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DuplicatesPopInReverseOrderOfPushes()
    var
        WorkStack: Codeunit "Work Stack";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Repeated: Text;
        Other: Text;
        Last: Text;
    begin
        // [SCENARIO] A value stored twice pops from the back like any other value
        Repeated := Any.AlphabeticText(6);
        Other := Any.AlphabeticText(7);
        Last := Any.AlphabeticText(8);
        WorkStack.Push(Repeated);
        WorkStack.Push(Other);
        WorkStack.Push(Repeated);
        WorkStack.Push(Last);

        Assert.AreEqual(Last + ',' + Repeated + ',' + Other + ',' + Repeated, DrainByPopping(WorkStack),
            'Expected a value pushed twice to pop from the back in strict reverse order — removing "the first occurrence" of the popped value takes the wrong copy when it is stored more than once');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PeekReturnsTheTopWithoutRemovingIt()
    var
        WorkStack: Codeunit "Work Stack";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        LastPushed: Text;
    begin
        // [SCENARIO] Peek shows the value on top and leaves the stack unchanged
        WorkStack.Push(Any.AlphabeticText(8));
        LastPushed := Any.AlphabeticText(8);
        WorkStack.Push(LastPushed);

        Assert.AreEqual(LastPushed, WorkStack.Peek(), 'Expected Peek to return the value pushed last');
        Assert.AreEqual(2, WorkStack.Count(), 'Expected Peek to leave every stored value in place');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PeekOnAnEmptyStackReturnsEmptyTextWithoutAnError()
    var
        WorkStack: Codeunit "Work Stack";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Peeking when nothing is stored returns an empty text instead of raising
        Assert.AreEqual('', WorkStack.Peek(), 'Expected Peek on an empty stack to return an empty text — Get(Index) raises for index 0, so guard the empty case instead of reading it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DequeueReturnsTheOldestValue()
    var
        WorkStack: Codeunit "Work Stack";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        FirstEnqueued: Text;
        Dequeued: Text;
    begin
        // [SCENARIO] Dequeue hands back the value enqueued first and removes it
        FirstEnqueued := Any.AlphabeticText(8);
        WorkStack.Enqueue(FirstEnqueued);
        WorkStack.Enqueue(Any.AlphabeticText(8));
        WorkStack.Enqueue(Any.AlphabeticText(8));

        Assert.IsTrue(WorkStack.Dequeue(Dequeued), 'Expected Dequeue to return true while a value is stored');
        Assert.AreEqual(FirstEnqueued, Dequeued, 'Expected Dequeue to hand out the value enqueued first — the front of the queue is index 1');
        Assert.AreEqual(2, WorkStack.Count(), 'Expected Dequeue to remove the dequeued value, leaving the two later enqueues stored');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DequeuesDrainInOrderOfEnqueues()
    var
        WorkStack: Codeunit "Work Stack";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        First: Text;
        Second: Text;
        Third: Text;
    begin
        // [SCENARIO] Repeated Dequeues return the enqueued values first in, first out
        First := Any.AlphabeticText(6);
        Second := Any.AlphabeticText(6);
        Third := Any.AlphabeticText(6);
        WorkStack.Enqueue(First);
        WorkStack.Enqueue(Second);
        WorkStack.Enqueue(Third);

        Assert.AreEqual(First + ',' + Second + ',' + Third, DrainByDequeuing(WorkStack),
            'Expected repeated Dequeues to hand out the values in the order they were enqueued (first in, first out) — read the front before removing it, because RemoveAt(1) shifts every remaining value down');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DuplicatesDequeueInFifoOrder()
    var
        WorkStack: Codeunit "Work Stack";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Repeated: Text;
        Other: Text;
        Last: Text;
    begin
        // [SCENARIO] A value enqueued twice comes out twice, each copy in its own position
        Repeated := Any.AlphabeticText(6);
        Other := Any.AlphabeticText(7);
        Last := Any.AlphabeticText(8);
        WorkStack.Enqueue(Repeated);
        WorkStack.Enqueue(Other);
        WorkStack.Enqueue(Repeated);
        WorkStack.Enqueue(Last);

        Assert.AreEqual(Repeated + ',' + Other + ',' + Repeated + ',' + Last, DrainByDequeuing(WorkStack),
            'Expected both copies of a value enqueued twice to be dequeued, each in the position it was added — duplicates must not be dropped or merged');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DequeueOnAnEmptyQueueReturnsFalseWithoutAnError()
    var
        WorkStack: Codeunit "Work Stack";
        Assert: Codeunit Assert;
        Dequeued: Text;
    begin
        // [SCENARIO] Dequeuing when nothing is stored reports false instead of raising
        Assert.IsFalse(WorkStack.Dequeue(Dequeued), 'Expected Dequeue on an empty queue to return false instead of raising an error — there is no index 1 in an empty list');
        Assert.AreEqual(0, WorkStack.Count(), 'Expected Count to stay 0 after a Dequeue on an empty queue');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PushesAndEnqueuesShareOneCollection()
    var
        WorkStack: Codeunit "Work Stack";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        First: Text;
        Second: Text;
        Third: Text;
    begin
        // [SCENARIO] Push and Enqueue append to the same list, so Dequeue sees both in arrival order
        First := Any.AlphabeticText(6);
        Second := Any.AlphabeticText(6);
        Third := Any.AlphabeticText(6);
        WorkStack.Push(First);
        WorkStack.Enqueue(Second);
        WorkStack.Push(Third);

        Assert.AreEqual(First + ',' + Second + ',' + Third, DrainByDequeuing(WorkStack),
            'Expected pushed and enqueued values to land in one list, so dequeuing returns all of them in the order they arrived');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountCountsPushesAndEnqueuesTogether()
    var
        WorkStack: Codeunit "Work Stack";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] Count reports every stored value regardless of how it was added
        WorkStack.Push(Any.AlphabeticText(6));
        WorkStack.Push(Any.AlphabeticText(6));
        WorkStack.Enqueue(Any.AlphabeticText(6));
        WorkStack.Enqueue(Any.AlphabeticText(6));

        Assert.AreEqual(4, WorkStack.Count(), 'Expected Count to report all four stored values after two pushes and two enqueues');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReverseTurnsPopOrderIntoQueueOrder()
    var
        WorkStack: Codeunit "Work Stack";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        First: Text;
        Second: Text;
        Third: Text;
    begin
        // [SCENARIO] After Reverse, popping yields the values in the order they were pushed
        First := Any.AlphabeticText(6);
        Second := Any.AlphabeticText(6);
        Third := Any.AlphabeticText(6);
        WorkStack.Push(First);
        WorkStack.Push(Second);
        WorkStack.Push(Third);

        WorkStack.Reverse();

        Assert.AreEqual(First, WorkStack.Peek(), 'Expected the value pushed first to sit at the back right after Reverse');
        Assert.AreEqual(First + ',' + Second + ',' + Third, DrainByPopping(WorkStack),
            'Expected Reverse to flip the stored order so that repeated Pops hand out the values first in, first out');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReverseTurnsDequeueOrderIntoStackOrder()
    var
        WorkStack: Codeunit "Work Stack";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        First: Text;
        Second: Text;
        Third: Text;
    begin
        // [SCENARIO] After Reverse, dequeuing yields the values in reverse order of enqueuing
        First := Any.AlphabeticText(6);
        Second := Any.AlphabeticText(6);
        Third := Any.AlphabeticText(6);
        WorkStack.Enqueue(First);
        WorkStack.Enqueue(Second);
        WorkStack.Enqueue(Third);

        WorkStack.Reverse();

        Assert.AreEqual(Third + ',' + Second + ',' + First, DrainByDequeuing(WorkStack),
            'Expected Reverse to reorder the stored values themselves, so that repeated Dequeues hand them out last in, first out — it must not merely redirect Pop');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PushAfterReverseLandsBehindTheReversedValues()
    var
        WorkStack: Codeunit "Work Stack";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        First: Text;
        Second: Text;
        Third: Text;
        Fourth: Text;
    begin
        // [SCENARIO] A value pushed after Reverse goes on the back of the reversed list and pops first
        First := Any.AlphabeticText(6);
        Second := Any.AlphabeticText(6);
        Third := Any.AlphabeticText(6);
        Fourth := Any.AlphabeticText(6);
        WorkStack.Push(First);
        WorkStack.Push(Second);
        WorkStack.Push(Third);
        WorkStack.Reverse();

        WorkStack.Push(Fourth);

        Assert.AreEqual(Fourth + ',' + First + ',' + Second + ',' + Third, DrainByPopping(WorkStack),
            'Expected a value pushed after Reverse to land at the back of the already reversed list, so it pops first and the earlier values follow in the order they were originally pushed — Reverse must reorder the stored values, not just swap which end Pop reads from');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DiscardRemovesOnlyTheFirstOccurrenceFromTheFront()
    var
        WorkStack: Codeunit "Work Stack";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Repeated: Text;
        Other: Text;
        Last: Text;
    begin
        // [SCENARIO] Discard removes the occurrence nearest the front and leaves the second copy
        Repeated := Any.AlphabeticText(6);
        Other := Any.AlphabeticText(7);
        Last := Any.AlphabeticText(8);
        WorkStack.Enqueue(Repeated);
        WorkStack.Enqueue(Other);
        WorkStack.Enqueue(Repeated);
        WorkStack.Enqueue(Last);

        Assert.IsTrue(WorkStack.Discard(Repeated), 'Expected Discard to return true when the value is stored');
        Assert.AreEqual(Other + ',' + Repeated + ',' + Last, DrainByDequeuing(WorkStack),
            'Expected Discard to remove exactly the first occurrence counted from the front and leave the second copy in place');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DiscardReturnsFalseWhenTheValueIsAbsent()
    var
        WorkStack: Codeunit "Work Stack";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] Discarding a value that is not stored reports false and changes nothing
        WorkStack.Enqueue(Any.AlphabeticText(6));

        Assert.IsFalse(WorkStack.Discard(Any.AlphabeticText(9)), 'Expected Discard to return false for a value that is not stored instead of raising an error');
        Assert.AreEqual(1, WorkStack.Count(), 'Expected a failed Discard to leave the stored value in place');
    end;

    // A Pop or Dequeue that never removes anything would loop forever; 20 is
    // well above the largest number of values any test stores.
    local procedure DrainByPopping(var WorkStack: Codeunit "Work Stack"): Text
    var
        Value: Text;
        Drained: Text;
        Taken: Integer;
    begin
        while (Taken < 20) and WorkStack.Pop(Value) do begin
            Taken += 1;
            if Taken > 1 then
                Drained += ',';
            Drained += Value;
        end;
        exit(Drained);
    end;

    local procedure DrainByDequeuing(var WorkStack: Codeunit "Work Stack"): Text
    var
        Value: Text;
        Drained: Text;
        Taken: Integer;
    begin
        while (Taken < 20) and WorkStack.Dequeue(Value) do begin
            Taken += 1;
            if Taken > 1 then
                Drained += ',';
            Drained += Value;
        end;
        exit(Drained);
    end;
}
