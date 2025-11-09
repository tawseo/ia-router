import { useMemo } from 'react';
import {
  DndContext,
  closestCenter,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
  DragEndEvent,
} from '@dnd-kit/core';
import {
  arrayMove,
  SortableContext,
  sortableKeyboardCoordinates,
  verticalListSortingStrategy,
} from '@dnd-kit/sortable';
import { Address } from '../types';
import AddressItem from './AddressItem';
import './AddressList.css';

interface AddressListProps {
  addresses: Address[];
  onReorder: (addresses: Address[]) => void;
  onStatusChange: (addressId: string, status: Address['status']) => void;
}

const AddressList = ({ addresses, onReorder, onStatusChange }: AddressListProps) => {
  const sensors = useSensors(
    useSensor(PointerSensor),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
    })
  );

  const sortedAddresses = useMemo(() => {
    return [...addresses].sort((a, b) => {
      if (a.manualOrder !== undefined && b.manualOrder !== undefined) {
        return a.manualOrder - b.manualOrder;
      }
      return 0;
    });
  }, [addresses]);

  const handleDragEnd = (event: DragEndEvent) => {
    const { active, over } = event;

    if (over && active.id !== over.id) {
      const oldIndex = sortedAddresses.findIndex(addr => addr.id === active.id);
      const newIndex = sortedAddresses.findIndex(addr => addr.id === over.id);

      const reordered = arrayMove(sortedAddresses, oldIndex, newIndex);
      onReorder(reordered);
    }
  };

  const validCount = addresses.filter(a => a.geocoded).length;
  const invalidCount = addresses.filter(a => !a.geocoded).length;

  return (
    <div className="address-list">
      <h2>Addresses ({addresses.length})</h2>

      <div className="address-stats">
        <span className="stat-valid">{validCount} valid</span>
        {invalidCount > 0 && (
          <span className="stat-invalid">{invalidCount} invalid</span>
        )}
      </div>

      <p className="help-text">Drag to reorder • Click status to change</p>

      <DndContext
        sensors={sensors}
        collisionDetection={closestCenter}
        onDragEnd={handleDragEnd}
      >
        <SortableContext
          items={sortedAddresses.map(a => a.id)}
          strategy={verticalListSortingStrategy}
        >
          <div className="address-items">
            {sortedAddresses.map((address, index) => (
              <AddressItem
                key={address.id}
                address={address}
                index={index}
                onStatusChange={onStatusChange}
              />
            ))}
          </div>
        </SortableContext>
      </DndContext>
    </div>
  );
};

export default AddressList;
