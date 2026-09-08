create table if not exists public.presentes (
  presente text primary key,
  nome text,
  reservado_em timestamptz
);

insert into public.presentes (presente) values
  ('Jogo de talher'),
  ('Jogo de copo'),
  ('Jogo de prato'),
  ('Jogo americano'),
  ('Porta mantimentos'),
  ('Canecas/xícaras'),
  ('Bacia/bowl'),
  ('Potes (tamanhos diversos)'),
  ('Porta detergente'),
  ('Pano de prato'),
  ('Tábua de carne'),
  ('Copo medidor'),
  ('Colher de arroz'),
  ('Concha'),
  ('Peneira'),
  ('Porta temperos'),
  ('Porta papel'),
  ('Saleiro'),
  ('Açucareiro'),
  ('Saboneteira'),
  ('Porta escovas'),
  ('Jogo de tapetes'),
  ('Vassoura/rodo/pá'),
  ('Pregador de roupa'),
  ('Balde'),
  ('Escova de roupa')
on conflict (presente) do nothing;

alter table public.presentes enable row level security;

drop policy if exists "public can read gifts" on public.presentes;
create policy "public can read gifts"
on public.presentes for select
to anon, authenticated
using (true);

create or replace function public.resgatar_presente(
  p_presente text,
  p_nome text
)
returns table (presente text, nome text, reservado_em timestamptz)
language plpgsql
security definer
set search_path = public
as $$
begin
  if length(trim(p_nome)) = 0 then
    raise exception 'Nome obrigatório';
  end if;

  return query
  update public.presentes
  set nome = trim(p_nome), reservado_em = now()
  where public.presentes.presente = p_presente
    and public.presentes.nome is null
  returning public.presentes.presente, public.presentes.nome, public.presentes.reservado_em;

  if not found then
    raise exception 'Este presente já foi resgatado';
  end if;
end;
$$;

revoke all on function public.resgatar_presente(text,text) from public;
grant execute on function public.resgatar_presente(text,text) to anon, authenticated;
grant select on public.presentes to anon, authenticated;
revoke update on public.presentes from anon, authenticated;


-- Ative as atualizações em tempo real da lista. Se já estiver ativa, ignore este comando.
alter publication supabase_realtime add table public.presentes;
