import { useSortable } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import { GripVertical, MapPin, AlertCircle } from 'lucide-react';
import { Address, DeliveryStatus } from '../types';
import './AddressItem.css';

interface AddressItemProps {
  address: Address;
  index: number;
  onStatusChange: (addressId: string, status: Address['status']) => void;
}

const statusOptions: DeliveryStatus[] = ['none', '1st', 'last', 'am', 'pm'];

const AddressItem = ({ address, index, onStatusChange }: AddressItemProps) => {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({ id: address.id });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.5 : 1,
  };

  const cycleStatus = () => {
    const currentIndex = statusOptions.indexOf(address.status || 'none');
    const nextIndex = (currentIndex + 1) % statusOptions.length;
    onStatusChange(address.id, statusOptions[nextIndex]);
  };

  const getStatusLabel = (status?: DeliveryStatus) => {
    if (!status || status === 'none') return '';
    return status.toUpperCase();
  };

  const getStatusClass = (status?: DeliveryStatus) => {
    if (!status || status === 'none') return '';
    return `status-${status}`;
  };

  return (
    <div
      ref={setNodeRef}
      style={style}
      className={`address-item ${!address.geocoded ? 'invalid' : ''} ${isDragging ? 'dragging' : ''}`}
    >
      <div className="drag-handle" {...attributes} {...listeners}>
        <GripVertical size={20} />
      </div>

      <div className="address-content">
        <div className="address-header">
          <span className="address-number">{index + 1}</span>
          <span className="address-text">{address.rawAddress}</span>
        </div>

        {address.coordinates && (
          <div className="address-coords">
            <MapPin size={14} />
            <span>
              {address.coordinates[0].toFixed(4)}, {address.coordinates[1].toFixed(4)}
            </span>
          </div>
        )}

        {!address.geocoded && (
          <div className="address-error">
            <AlertCircle size={14} />
            <span>{address.error || 'Could not geocode'}</span>
          </div>
        )}
      </div>

      <button
        className={`status-badge ${getStatusClass(address.status)}`}
        onClick={cycleStatus}
        title="Click to change status"
      >
        {getStatusLabel(address.status) || 'NONE'}
      </button>
    </div>
  );
};

export default AddressItem;
